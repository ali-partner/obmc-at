// SPDX-License-Identifier: GPL-2.0

/*
 * IPMB driver to receive a request and send a response
 *
 * Copyright (C) 2019 Mellanox Techologies, Ltd.
 *
 * This was inspired by Brendan Higgins' ipmi-bmc-bt-i2c driver.
 */

#include <linux/acpi.h>
#include <linux/errno.h>
#include <linux/i2c.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/poll.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/wait.h>
#include <linux/hwmon.h>
#include <linux/hwmon-vid.h>
#include <linux/hwmon-sysfs.h>

#define MAX_MSG_LEN		240
#define IPMB_REQUEST_LEN_MIN	7
#define NETFN_RSP_BIT_MASK	0x4
#define REQUEST_QUEUE_MAX_LEN	256

#define IPMB_MSG_LEN_IDX	0
#define RQ_SA_8BIT_IDX		1
#define NETFN_LUN_IDX		2

#define GET_7BIT_ADDR(addr_8bit)	(addr_8bit >> 1)
#define GET_8BIT_ADDR(addr_7bit)	((addr_7bit << 1) & 0xff)

#define IPMB_MSG_PAYLOAD_LEN_MAX (MAX_MSG_LEN - IPMB_REQUEST_LEN_MIN - 1)

#define SMBUS_MSG_HEADER_LENGTH	2
#define SMBUS_MSG_IDX_OFFSET	(SMBUS_MSG_HEADER_LENGTH + 1)

struct ipmb_msg {
	u8 len;
	u8 rs_sa;
	u8 netfn_rs_lun;
	u8 checksum1;
	u8 rq_sa;
	u8 rq_seq_rq_lun;
	u8 cmd;
	u8 payload[IPMB_MSG_PAYLOAD_LEN_MAX];
	/* checksum2 is included in payload */
} __packed;

struct ipmb_request_elem {
	struct list_head list;
	struct ipmb_msg request;
};

#define OEM_MODE        1
#define ORIGIN_MODE     0

struct ipmb_dev {
    struct device *hwmon_dev;
	struct i2c_client *client;
	struct miscdevice miscdev;
	struct ipmb_msg request;
	struct ipmb_msg oem_request;
	struct list_head request_queue;
	struct list_head oem_request_queue;
	atomic_t request_queue_len;
	atomic_t oem_request_queue_len;
	size_t msg_idx;
	spinlock_t lock;
	wait_queue_head_t wait_queue;
	wait_queue_head_t oem_wait_queue;
	struct mutex file_mutex;
	bool is_i2c_protocol;
	bool is_oem_mode;
};

static inline struct ipmb_dev *to_ipmb_dev(struct file *file)
{
	return container_of(file->private_data, struct ipmb_dev, miscdev);
}

static ssize_t ipmb_read(struct file *file, char __user *buf, size_t count,
			loff_t *ppos)
{
	struct ipmb_dev *ipmb_dev = to_ipmb_dev(file);
	struct ipmb_request_elem *queue_elem;
	struct ipmb_msg msg;
	ssize_t ret = 0;


	memset(&msg, 0, sizeof(msg));

	mutex_lock(&ipmb_dev->file_mutex);

	spin_lock_irq(&ipmb_dev->lock);

	while (list_empty(&ipmb_dev->request_queue)) {
		spin_unlock_irq(&ipmb_dev->lock);
		mutex_unlock(&ipmb_dev->file_mutex);

		if (file->f_flags & O_NONBLOCK)
			return -EAGAIN;

		ret = wait_event_interruptible(ipmb_dev->wait_queue,
				!list_empty(&ipmb_dev->request_queue));
		if (ret)
			return ret;

		spin_lock_irq(&ipmb_dev->lock);
	}

	queue_elem = list_first_entry(&ipmb_dev->request_queue,
					struct ipmb_request_elem, list);
	memcpy(&msg, &queue_elem->request, sizeof(msg));
	list_del(&queue_elem->list);
	kfree(queue_elem);
	atomic_dec(&ipmb_dev->request_queue_len);

	spin_unlock_irq(&ipmb_dev->lock);
	mutex_unlock(&ipmb_dev->file_mutex);

	count = min_t(size_t, count, msg.len + 1);
	if (copy_to_user(buf, &msg, count))
		ret = -EFAULT;

	return ret < 0 ? ret : count;
}

static int ipmb_i2c_write(struct i2c_client *client, u8 *msg, u8 addr)
{
	struct i2c_msg i2c_msg;

	/*
	 * subtract 1 byte (rq_sa) from the length of the msg passed to
	 * raw i2c_transfer
	 */
	i2c_msg.len = msg[IPMB_MSG_LEN_IDX] - 1;

	/* Assign message to buffer except first 2 bytes (length and address) */
	i2c_msg.buf = msg + 2;

	i2c_msg.addr = addr;
	i2c_msg.flags = client->flags & I2C_CLIENT_PEC;

	return i2c_transfer(client->adapter, &i2c_msg, 1);
}

static ssize_t ipmb_write(struct file *file, const char __user *buf,
			size_t count, loff_t *ppos)
{
	struct ipmb_dev *ipmb_dev = to_ipmb_dev(file);
	u8 rq_sa, netf_rq_lun, msg_len;
	struct i2c_client *temp_client;
	u8 msg[MAX_MSG_LEN];
	ssize_t ret;


	if (count > sizeof(msg))
		return -EINVAL;

	if (copy_from_user(&msg, buf, count))
		return -EFAULT;

	if (count < msg[0])
		return -EINVAL;

	rq_sa = GET_7BIT_ADDR(msg[RQ_SA_8BIT_IDX]);
	netf_rq_lun = msg[NETFN_LUN_IDX];

    mutex_lock(&ipmb_dev->file_mutex);
	/* Check i2c block transfer vs smbus */
	if (ipmb_dev->is_i2c_protocol) {
		ret = ipmb_i2c_write(ipmb_dev->client, msg, rq_sa);
		mutex_unlock(&ipmb_dev->file_mutex);
		return (ret == 1) ? count : ret;
	}

    /*
     * subtract rq_sa and netf_rq_lun from the length of the msg. Fill the
     * temporary client. Note that its use is an exception for IPMI.
     */
    msg_len = msg[IPMB_MSG_LEN_IDX] - SMBUS_MSG_HEADER_LENGTH;
    temp_client = kmemdup(ipmb_dev->client, sizeof(*temp_client), GFP_KERNEL);
    if (!temp_client)
        return -ENOMEM;

    temp_client->addr = rq_sa;

    ret = i2c_smbus_write_block_data(temp_client, netf_rq_lun, msg_len,
                     msg + SMBUS_MSG_IDX_OFFSET);
    kfree(temp_client);

    mutex_unlock(&ipmb_dev->file_mutex);

    return ret < 0 ? ret : count;
}

static __poll_t ipmb_poll(struct file *file, poll_table *wait)
{
	struct ipmb_dev *ipmb_dev = to_ipmb_dev(file);
	__poll_t mask = EPOLLOUT;

	spin_lock_irq(&ipmb_dev->lock);
	poll_wait(file, &ipmb_dev->wait_queue, wait);

	if (atomic_read(&ipmb_dev->request_queue_len))
		mask |= EPOLLIN;
	spin_unlock_irq(&ipmb_dev->lock);

	return mask;
}

static __poll_t oem_ipmb_poll(struct file *file, poll_table *wait)
{
	struct ipmb_dev *ipmb_dev = to_ipmb_dev(file);
	__poll_t mask = EPOLLOUT;

	spin_lock_irq(&ipmb_dev->lock);
	poll_wait(file, &ipmb_dev->oem_wait_queue, wait);

	if (atomic_read(&ipmb_dev->oem_request_queue_len))
		mask |= EPOLLIN;
	spin_unlock_irq(&ipmb_dev->lock);

	return mask;
}


static const struct file_operations ipmb_fops = {
	.owner	= THIS_MODULE,
	.read	= ipmb_read,
	.write	= ipmb_write,
	.poll	= ipmb_poll,
};

/* Called with ipmb_dev->lock held. */
static void ipmb_handle_request(struct ipmb_dev *ipmb_dev)
{
	struct ipmb_request_elem *queue_elem;

	if (atomic_read(&ipmb_dev->request_queue_len) >=
			REQUEST_QUEUE_MAX_LEN)
		return;

	queue_elem = kmalloc(sizeof(*queue_elem), GFP_ATOMIC);
	if (!queue_elem)
		return;

	memcpy(&queue_elem->request, &ipmb_dev->request,
		sizeof(struct ipmb_msg));
	list_add(&queue_elem->list, &ipmb_dev->request_queue);
	atomic_inc(&ipmb_dev->request_queue_len);

    wake_up_all(&ipmb_dev->wait_queue);
}


/* Called with ipmb_dev->lock held. */
static void oem_ipmb_handle_request(struct ipmb_dev *ipmb_dev)
{
	struct ipmb_request_elem *queue_elem;

	if (atomic_read(&ipmb_dev->oem_request_queue_len) >=
			REQUEST_QUEUE_MAX_LEN)
		return;

	queue_elem = kmalloc(sizeof(*queue_elem), GFP_ATOMIC);
	if (!queue_elem)
		return;

	memcpy(&queue_elem->request, &ipmb_dev->oem_request,
		sizeof(struct ipmb_msg));
	list_add(&queue_elem->list, &ipmb_dev->oem_request_queue);
	atomic_inc(&ipmb_dev->oem_request_queue_len);

    wake_up_all(&ipmb_dev->oem_wait_queue);
}

static u8 ipmb_verify_checksum1(struct ipmb_dev *ipmb_dev, u8 rs_sa)
{
	/* The 8 lsb of the sum is 0 when the checksum is valid */
	if (OEM_MODE == ipmb_dev->is_oem_mode)
	{
	    return (rs_sa + ipmb_dev->oem_request.netfn_rs_lun +
		    ipmb_dev->oem_request.checksum1);
	}
	else
	{
	    return (rs_sa + ipmb_dev->request.netfn_rs_lun +
		    ipmb_dev->request.checksum1);
	}
}

/*
 * Verify if message has proper ipmb header with minimum length
 * and correct checksum byte.
 */
static bool is_ipmb_msg(struct ipmb_dev *ipmb_dev, u8 rs_sa)
{
	if ((ipmb_dev->msg_idx >= IPMB_REQUEST_LEN_MIN) &&
	   (!ipmb_verify_checksum1(ipmb_dev, rs_sa)))
		return true;

	return false;
}

/*
 * The IPMB protocol only supports I2C Writes so there is no need
 * to support I2C_SLAVE_READ* events.
 * This i2c callback function only monitors IPMB request messages
 * and adds them in a queue, so that they can be handled by
 * receive_ipmb_request.
 */
static int ipmb_slave_cb(struct i2c_client *client,
			enum i2c_slave_event event, u8 *val)
{
	struct ipmb_dev *ipmb_dev = i2c_get_clientdata(client);
	u8 *buf = (OEM_MODE == ipmb_dev->is_oem_mode) ? (u8 *)&ipmb_dev->oem_request : (u8 *)&ipmb_dev->request;
	unsigned long flags;

	spin_lock_irqsave(&ipmb_dev->lock, flags);
	switch (event) {
	case I2C_SLAVE_WRITE_REQUESTED:
	    if (OEM_MODE == ipmb_dev->is_oem_mode)
	    {
	        memset(&ipmb_dev->oem_request, 0, sizeof(ipmb_dev->oem_request));
	    }
	    else
	    {
            memset(&ipmb_dev->request, 0, sizeof(ipmb_dev->request));
	    }
		ipmb_dev->msg_idx = 0;

		/*
		 * At index 0, ipmb_msg stores the length of msg,
		 * skip it for now.
		 * The len will be populated once the whole
		 * buf is populated.
		 *
		 * The I2C bus driver's responsibility is to pass the
		 * data bytes to the backend driver; it does not
		 * forward the i2c slave address.
		 * Since the first byte in the IPMB message is the
		 * address of the responder, it is the responsibility
		 * of the IPMB driver to format the message properly.
		 * So this driver prepends the address of the responder
		 * to the received i2c data before the request message
		 * is handled in userland.
		 */
		buf[++ipmb_dev->msg_idx] = GET_8BIT_ADDR(client->addr);
		break;

	case I2C_SLAVE_WRITE_RECEIVED:
		if (ipmb_dev->msg_idx >= sizeof(struct ipmb_msg) - 1)
			break;

		buf[++ipmb_dev->msg_idx] = *val;
		break;

	case I2C_SLAVE_STOP:
	    if (OEM_MODE == ipmb_dev->is_oem_mode)
	    {
            ipmb_dev->oem_request.len = ipmb_dev->msg_idx;
            if (is_ipmb_msg(ipmb_dev, GET_8BIT_ADDR(client->addr)))
                oem_ipmb_handle_request(ipmb_dev);
	    }
	    else
	    {
            ipmb_dev->request.len = ipmb_dev->msg_idx;
            if (is_ipmb_msg(ipmb_dev, GET_8BIT_ADDR(client->addr)))
                ipmb_handle_request(ipmb_dev);
	    }
		break;

	default:
		break;
	}
	spin_unlock_irqrestore(&ipmb_dev->lock, flags);

	return 0;
}

#define LUN                 0
#define NETFN_OEM           0x2e
#define ME_ADDR             0x16
#define BMC_ADDR            0x10
#define CMD_PECI_PROXY      0x40
#define PECI_CLIENT_ADDR    0x30

#define IPMB_XFER_DEFAULT_TIMEOUT 5 /* seconds */

static char ipmbChecksumCompute(char *data, char length)
{
    char checksum = 0;
    char idx = 0;

    // compute checksum.
    for (idx = 0; idx < length; idx++)
    {
        checksum += data[idx];
    }

    checksum = (~checksum) + 1;

    // return computed checksum value.
    return checksum;
}

struct oem_ipmb_poll_info_s {
    struct wait_queue_head *wait_address;
    poll_table pt;
} ;

static void oem_ipmb_xfer_pollwait(struct file *filp, wait_queue_head_t *wait_address, poll_table *p)
{
    struct oem_ipmb_poll_info_s * pinfo = container_of(p, struct oem_ipmb_poll_info_s, pt);
    pinfo->wait_address = wait_address;
    return ;
}

int oem_ipmb_xfer_poll(struct file * fp, long timeout)
{
    long ret = 500;
    unsigned long mask;
    struct oem_ipmb_poll_info_s pinfo = {0};

    init_poll_funcptr(&pinfo.pt, oem_ipmb_xfer_pollwait);

    mask = oem_ipmb_poll(fp, &pinfo.pt);
    if (0 != (mask & POLLIN))
    {
        return 0;
    }
    timeout = (timeout <= 0) ? IPMB_XFER_DEFAULT_TIMEOUT : timeout;

    ret = wait_event_interruptible_timeout(*pinfo.wait_address, (oem_ipmb_poll(fp, &pinfo.pt) & POLLIN) != 0, (timeout*HZ));

    /*
    * It returns 1 if the condition evaluated to true after the timeout elapsed, the remaining jiggies (at least 1)
    * if the condition evaluated to true before the timeout elapsed.
    */
    if (ret > 0)
    {
        return 0;
    }

    /* It returns 0 if the condition evaluated to false after the timeout elapsed. */
    if (0 == ret)
    {
        return -ETIMEDOUT;
    }

    /* It returns -ERESTARTSYS if it was interrupted by a signal. */
    return (int)ret;
}

static int oem_ipmb_xfer(struct file * fp, char * req, char * rsp)
{
    ssize_t ret = 0;
    struct ipmb_dev *ipmb_dev = to_ipmb_dev(fp);
    struct i2c_client *client = ipmb_dev->client;
    struct ipmb_request_elem *queue_elem;
	struct ipmb_msg *msg = (struct ipmb_msg *)rsp;
	__poll_t mask = EPOLLOUT;
	long timeout = 0;

    /* Send request ... */
    /* Check i2c block transfer vs smbus */
	if (NULL == ipmb_dev->is_i2c_protocol) {
        return -1;
	}

	mutex_lock(&ipmb_dev->file_mutex);

	ipmb_dev->is_oem_mode = OEM_MODE;

    ret = ipmb_i2c_write(client, req, ME_ADDR);
    if (ret != 1)
    {
        ipmb_dev->is_oem_mode = ORIGIN_MODE;
        mutex_unlock(&ipmb_dev->file_mutex);
        return -1;
    }
    else
    {
        ret = 0;
    }

    /* Poll... */
    mask = oem_ipmb_xfer_poll(fp, timeout);

    /* Get response ... */
    spin_lock_irq(&ipmb_dev->lock);

    while (list_empty(&ipmb_dev->oem_request_queue)) {
        spin_unlock_irq(&ipmb_dev->lock);

        if (fp->f_flags & O_NONBLOCK)
        {
            ipmb_dev->is_oem_mode = ORIGIN_MODE;
            mutex_unlock(&ipmb_dev->file_mutex);
            return -EAGAIN;
        }

        ret = wait_event_interruptible(ipmb_dev->oem_wait_queue, !list_empty(&ipmb_dev->oem_request_queue));
        if (ret)
        {
            ipmb_dev->is_oem_mode = ORIGIN_MODE;
            mutex_unlock(&ipmb_dev->file_mutex);
            return ret;
        }

        spin_lock_irq(&ipmb_dev->lock);
    }

    queue_elem = list_first_entry(&ipmb_dev->oem_request_queue, struct ipmb_request_elem, list);
    memcpy(msg, &queue_elem->request, sizeof(struct ipmb_msg));
    list_del(&queue_elem->list);
    kfree(queue_elem);
    atomic_dec(&ipmb_dev->oem_request_queue_len);

    spin_unlock_irq(&ipmb_dev->lock);
    ipmb_dev->is_oem_mode = ORIGIN_MODE;
    mutex_unlock(&ipmb_dev->file_mutex);

    /* See 513973-nm-3-0-external-interface-spec-r2pt3.pdf
       Table 2-13 IPMI OEM PECI Proxy Commands Definition
       Response Byte 1 �C Completion Code
       (Remaining standard Completion Codes are shown in Section 2.11)
       =00h �C PECI response successfully retuned (see PECI response
       Completion Code for detailed response from PECI client, which
       may be not fully successful).
       =A2h �C Command response timeout.
       =A4h �C Bad read FSC in the response.
       =A5h �C Bad write FCS field in the response.
       =A8h - Selected PECI interface not available
       =ABh �C Wrong command code.
       =ACh �C CPU not present.
       =D5h �C Platform not in S0/S1 state.
       =FFh �C Other error encountered.
    */
    ret = 0;
    if (0 != msg->payload[0])
    {
        ret = (1 << 8) | msg->payload[0];
    }
    return ret;
}

/* PECI GetTEMP() */
static char cmd_peci_temp[3] = {0x1, 0x2, 0x1};
/* PECI RdPkgConfig() index=0x10: Processor Tj,max and Tcontrol  */
static char cmd_tjmax[7] = {0x5, 0x5, 0xa1, 0x0, 0x10, 0x0, 0x0};

static unsigned int ipmb_status_value = 0;
static unsigned int lpc_x86_value = 0;

/* IPMB frame structure:
abbreviation Field definition	                    Example:  Example:
                                                    peci_temp tjmax

length	     length of whole                        0xe	      0x12
             IPMB frame

addr	     responder's slave addr                 0x2c	  0x2c
             (8-bit i2c addr),
             eg ME addr for BMC is 0x16,
             here addr is 0x2c(0x16<<1).

rsNetFnLUN	 (NetFn<<2)|LUN	                        0xb8	  0xb8

checksum1	 checksum1(addr and rsNetFnLUN)	        0x1c	  0x1c

rqSA	     requester's slave addr                 0x20	  0x20
             (8-bit i2c addr),
             eg BMC addr for ME is 0x10,
             here rqSA is 0x20(0x10<<1).

rqSeqLUN	 requester's sequence number and LUN	0x4	      0x8

cmd	         cmd	                                0x40	  0x40

payload	     payload	                            0x57      0x57
                                                    0x1       0x1
                                                    0x0       0x0
                                                    0x30      0x30
                                                    0x1       0x5
                                                    0x2       0x5
                                                    0x1	      0xa1
                                                              0x0
                                                              0x10
                                                              0x0
                                                              0x0

checksum	 checksum(from rqSA to payload)	        0x10	  0x55

*/

static void gen_ipmb_tx_msg(struct ipmb_msg *msg , char rs_sa, char netfn, char rs_lun, char rq_sa, char rq_seq, char rq_lun, char cmd_type, char client_addr, char *cmd, char cmd_len)
{
	int checksum_len = 0;
	char intel_manu_id[3] = {0x57, 0x01, 0x00};
    int payload_len = 0;

    msg->rs_sa = rs_sa << 1;
    msg->netfn_rs_lun = (netfn << 2) | rs_lun;
    checksum_len = sizeof(msg->rs_sa) + sizeof(msg->netfn_rs_lun);
    msg->checksum1 = ipmbChecksumCompute(&(msg->rs_sa), checksum_len);
    msg->rq_sa = rq_sa << 1;
    msg->rq_seq_rq_lun = (rq_seq << 2) | rq_lun;
    msg->cmd = cmd_type;
    payload_len = sizeof(intel_manu_id) + 1 + cmd_len; /* PECI_CLIENT_ADDR is 1 Byte. */
    memcpy(msg->payload, intel_manu_id, sizeof(intel_manu_id));
    msg->payload[sizeof(intel_manu_id)] = client_addr;
    memcpy(msg->payload + 1 + sizeof(intel_manu_id), cmd, cmd_len);

    checksum_len = sizeof(msg->rq_sa)
                 + sizeof(msg->netfn_rs_lun)
                 + sizeof(msg->cmd)
                 + payload_len;
    msg->payload[payload_len] = ipmbChecksumCompute(&(msg->rq_sa), checksum_len);

    msg->len = sizeof(msg->len)
             + sizeof(msg->rs_sa)
             + sizeof(msg->netfn_rs_lun)
             + sizeof(msg->checksum1)
             + checksum_len;

}

static ssize_t show_tjmax(struct device *dev, struct device_attribute *attr, char *buf)
{
    ssize_t ret = 0;
    struct ipmb_dev *ipmb_dev = dev_get_drvdata(dev);
    unsigned int tjmax = 255;
    struct ipmb_request_elem *queue_elem;
	struct ipmb_msg tx_msg, rx_msg;
	__poll_t mask = EPOLLOUT;
	struct file * fp;
	char dev_name[128] = {0};

    memset(&tx_msg, 0, sizeof(tx_msg));
    memset(&rx_msg, 0, sizeof(rx_msg));

    /* Open "/dev/ipmb-0" */
    snprintf(dev_name, sizeof(dev_name), "/dev/%s", ipmb_dev->miscdev.name);
	fp = filp_open(dev_name, O_RDWR | O_NONBLOCK, S_IRWXU);
    if(IS_ERR_OR_NULL(fp))
    {
        filp_close(fp, NULL);
        return -ENOENT;
    }

    gen_ipmb_tx_msg(&tx_msg, ME_ADDR, NETFN_OEM, LUN, BMC_ADDR, 0x2, LUN, CMD_PECI_PROXY, PECI_CLIENT_ADDR, cmd_tjmax, sizeof(cmd_tjmax));
	ret = oem_ipmb_xfer(fp, (char *)&tx_msg, (char *)&rx_msg);
    filp_close(fp, NULL);

    tjmax = (0 == ret) ? rx_msg.payload[7] : ret;
    return scnprintf(buf, PAGE_SIZE, "%d\n", tjmax);
}

static ssize_t show_peci_temp(struct device *dev, struct device_attribute *attr, char *buf)
{
    ssize_t ret = 0;
    struct ipmb_dev *ipmb_dev = dev_get_drvdata(dev);
    short peci_temp = -50;
    short format_peci_temp = -50;
	struct ipmb_msg tx_msg, rx_msg;
    __poll_t mask = EPOLLOUT;
    struct file * fp;
	char dev_name[128] = {0};

    memset(&tx_msg, 0, sizeof(tx_msg));
    memset(&rx_msg, 0, sizeof(rx_msg));

    /* Open "/dev/ipmb-0" */
    snprintf(dev_name, sizeof(dev_name), "/dev/%s", ipmb_dev->miscdev.name);
    fp = filp_open(dev_name, O_RDWR | O_NONBLOCK, S_IRWXU);
    if(IS_ERR_OR_NULL(fp))
    {
        filp_close(fp, NULL);
        return -ENOENT;
    }
    gen_ipmb_tx_msg(&tx_msg, ME_ADDR, NETFN_OEM, LUN, BMC_ADDR, 0x1, LUN, CMD_PECI_PROXY, PECI_CLIENT_ADDR, cmd_peci_temp, sizeof(cmd_peci_temp));
	ret = oem_ipmb_xfer(fp, (char *)&tx_msg, (char *)&rx_msg);
    filp_close(fp, NULL);

    if (0 == ret)
    {
        peci_temp = (rx_msg.payload[5] << 8) | rx_msg.payload[4];
        format_peci_temp = peci_temp >> 6;
        return scnprintf(buf, PAGE_SIZE, "%d\n", format_peci_temp);
    }
    else
    {
        return scnprintf(buf, PAGE_SIZE, "%d\n", 255);
    }
}


static ssize_t show_host_temp(struct device *dev, struct device_attribute *attr, char *buf)
{
    ssize_t ret = 0;
    struct ipmb_dev *ipmb_dev = dev_get_drvdata(dev);
    int host_temp = 0;
    short tjmax = 0;
    short peci_temp = 0;
    struct ipmb_msg tx_msg, rx_msg;
    __poll_t mask = EPOLLOUT;
    struct file * fp;
    char dev_name[128] = {0};

    while(true)
    {
        memset(&tx_msg, 0, sizeof(tx_msg));
        memset(&rx_msg, 0, sizeof(rx_msg));

        /* Open "/dev/ipmb-0" */
        snprintf(dev_name, sizeof(dev_name), "/dev/%s", ipmb_dev->miscdev.name);
        fp = filp_open(dev_name, O_RDWR | O_NONBLOCK, S_IRWXU);
        if(IS_ERR_OR_NULL(fp))
        {
            filp_close(fp, NULL);
            return -ENOENT;
        }
        gen_ipmb_tx_msg(&tx_msg, ME_ADDR, NETFN_OEM, LUN, BMC_ADDR, 0x2, LUN, CMD_PECI_PROXY, PECI_CLIENT_ADDR, cmd_tjmax, sizeof(cmd_tjmax));
        ret = oem_ipmb_xfer(fp, (char *)&tx_msg, (char *)&rx_msg);
        filp_close(fp, NULL);

        if (0 != ret)
        {
            ipmb_status_value = 1;
            return scnprintf(buf, PAGE_SIZE, "%d\n", lpc_x86_value);
        }
        else
        {
            //ipmb_status_value = 0;
        }

        tjmax = rx_msg.payload[7];

        memset(&tx_msg, 0, sizeof(tx_msg));
        memset(&rx_msg, 0, sizeof(rx_msg));
        fp = filp_open(dev_name, O_RDWR | O_NONBLOCK, S_IRWXU);
        if(IS_ERR_OR_NULL(fp))
        {
            filp_close(fp, NULL);
            return -ENOENT;
        }
        gen_ipmb_tx_msg(&tx_msg, ME_ADDR, NETFN_OEM, LUN, BMC_ADDR, 0x1, LUN, CMD_PECI_PROXY, PECI_CLIENT_ADDR, cmd_peci_temp, sizeof(cmd_peci_temp));
    	ret = oem_ipmb_xfer(fp, (char *)&tx_msg, (char *)&rx_msg);
        filp_close(fp, NULL);

        if (0 != ret)
        {
            ipmb_status_value = 1;
            return scnprintf(buf, PAGE_SIZE, "%d\n", lpc_x86_value);
        }
        else
        {
            //ipmb_status_value = 0;
        }

        peci_temp = (rx_msg.payload[5] << 8) | rx_msg.payload[4];
        peci_temp >>= 6;
        if((tjmax != 0) && (peci_temp < 0))
            break;
    }

    host_temp = ((int)(tjmax + peci_temp)) * 1000;
    return scnprintf(buf, PAGE_SIZE, "%d\n", host_temp);
}

static ssize_t ipmb_status_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    return scnprintf(buf, PAGE_SIZE, "%d\n", ipmb_status_value);
}

static ssize_t ipmb_status_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count)
{
    struct ipmb_dev *ipmb_dev = dev_get_drvdata(dev);
    mutex_lock(&ipmb_dev->file_mutex);
    sscanf(buf, "%i", &ipmb_status_value);
    mutex_unlock(&ipmb_dev->file_mutex);
    return count;
}

static ssize_t lpc_x86_temp_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    return scnprintf(buf, PAGE_SIZE, "%d\n", lpc_x86_value);
}

static ssize_t lpc_x86_temp_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count)
{
    struct ipmb_dev *ipmb_dev = dev_get_drvdata(dev);
    mutex_lock(&ipmb_dev->file_mutex);
    sscanf(buf, "%i", &lpc_x86_value);
    mutex_unlock(&ipmb_dev->file_mutex);
    return count;
}

static struct sensor_device_attribute tjmax = SENSOR_ATTR(host_tjmax, S_IRUGO, show_tjmax, NULL, 0);
static struct sensor_device_attribute peci_temp = SENSOR_ATTR(host_peci_temp, S_IRUGO, show_peci_temp, NULL, 0);
static struct sensor_device_attribute host_temp = SENSOR_ATTR(temp1_input, S_IRUGO, show_host_temp, NULL, 0);
static struct sensor_device_attribute ipmb_status = SENSOR_ATTR(ipmb_status,  S_IRUGO | S_IWUSR, ipmb_status_show, ipmb_status_store, 0);
static struct sensor_device_attribute lpc_x86_temp = SENSOR_ATTR(lpc_x86_temp,  S_IRUGO | S_IWUSR, lpc_x86_temp_show, lpc_x86_temp_store, 0);



static struct attribute *ipmb_sysfs_attributes[] = {
    &tjmax.dev_attr.attr,
    &peci_temp.dev_attr.attr,
    &host_temp.dev_attr.attr,
    &ipmb_status.dev_attr.attr,
    &lpc_x86_temp.dev_attr.attr,
    NULL
};


static const struct attribute_group ipmb_sysfs_group = {
    .attrs = ipmb_sysfs_attributes,
};

static const struct attribute_group *ipmb_sysfs_groups_array[] = {
    &ipmb_sysfs_group,
    NULL
};

static int ipmb_probe(struct i2c_client *client)
{
	struct ipmb_dev *ipmb_dev;
	int ret;

	ipmb_dev = devm_kzalloc(&client->dev, sizeof(*ipmb_dev),
					GFP_KERNEL);
	if (!ipmb_dev)
		return -ENOMEM;

	spin_lock_init(&ipmb_dev->lock);
	init_waitqueue_head(&ipmb_dev->wait_queue);
	init_waitqueue_head(&ipmb_dev->oem_wait_queue);
	atomic_set(&ipmb_dev->request_queue_len, 0);
	atomic_set(&ipmb_dev->oem_request_queue_len, 0);
	INIT_LIST_HEAD(&ipmb_dev->request_queue);
	INIT_LIST_HEAD(&ipmb_dev->oem_request_queue);

	mutex_init(&ipmb_dev->file_mutex);

	ipmb_dev->miscdev.minor = MISC_DYNAMIC_MINOR;

	ipmb_dev->miscdev.name = devm_kasprintf(&client->dev, GFP_KERNEL,
						"%s%d", "ipmb-",
						client->adapter->nr);
	ipmb_dev->miscdev.fops = &ipmb_fops;
	ipmb_dev->miscdev.parent = &client->dev;
	ret = misc_register(&ipmb_dev->miscdev);
	if (ret)
		return ret;

	ipmb_dev->is_i2c_protocol
		= device_property_read_bool(&client->dev, "i2c-protocol");

    ipmb_dev->is_oem_mode = ORIGIN_MODE;

	ipmb_dev->client = client;
	i2c_set_clientdata(client, ipmb_dev);
	ret = i2c_slave_register(client, ipmb_slave_cb);
	if (ret) {
		misc_deregister(&ipmb_dev->miscdev);
		return ret;
	}

	/* Everything is ready, now register the working device */
	ipmb_dev->hwmon_dev = hwmon_device_register_with_info(&client->dev, client->name, ipmb_dev, NULL, ipmb_sysfs_groups_array);
	if (IS_ERR(ipmb_dev->hwmon_dev))
	{
	    ret = PTR_ERR(ipmb_dev->hwmon_dev);
	    return ret;
	}

	return 0;
}

static void ipmb_remove(struct i2c_client *client)
{
	struct ipmb_dev *ipmb_dev = i2c_get_clientdata(client);

	i2c_slave_unregister(client);
	misc_deregister(&ipmb_dev->miscdev);
}

static const struct i2c_device_id ipmb_id[] = {
	{ "ipmb-dev", 0 },
	{},
};
MODULE_DEVICE_TABLE(i2c, ipmb_id);

static const struct acpi_device_id acpi_ipmb_id[] = {
	{ "IPMB0001", 0 },
	{},
};
MODULE_DEVICE_TABLE(acpi, acpi_ipmb_id);

static struct i2c_driver ipmb_driver = {
	.driver = {
		.name = "ipmb-dev",
		.acpi_match_table = ACPI_PTR(acpi_ipmb_id),
	},
	.probe = ipmb_probe,
	.remove = ipmb_remove,
	.id_table = ipmb_id,
};
module_i2c_driver(ipmb_driver);

MODULE_AUTHOR("Mellanox Technologies");
MODULE_DESCRIPTION("IPMB driver");
MODULE_LICENSE("GPL v2");

