#!/bin/bash
set -euo pipefail
#====================Configuration====================
MAGIC="NMX-36/V1.0"
MAGIC_BYTE_LEN=12
PRODUCT_NAME_MAX_LEN=16
FW_TYPE_MAX_LEN=16
META_HEAD_BASE_LEN=48
SHA512_HASH_BYTES=64
META_HEAD_TOTAL_LEN=$((META_HEAD_BASE_LEN + SHA512_HASH_BYTES))
#=====================================================
#[MAGIC(12B)][fw_len(4B)][PRODUCT_NAME(16B)][FW_TYPE(16B)][SHA512_HASH(64B)]
# No RSA signature. Use SHA512 for integrity check only.
# Special: product_name argument accept "NA" to skip product name verification
# Warning: SHA512 only detect accidental corruption, NOT resist malicious tamper.

usage() {
    echo "Usage: ${0##*/} <product_name> <fw_type> <sign_fw_file> <out_fw_file>"
    echo "    <product_name>: NA | S8630-64H | AS42-64S-AT"
    echo "    <fw_type>: BMC | BIOS | SYS_CPLD | OCM_CPLD | MISC_CPLD | PORT_CPLD1 | PORT_CPLD2 | LED_CPLD | FAN_CPLD | FPGA"
    echo "    <sign_fw_file>: signature firmware file"
    echo "    <out_fw_file>: full path + filename for output restored firmware"
    echo "Note: NA=skip product name check!"
    echo "Note: SHA512 integrity check enabled, NO RSA signature!"
}

# total 4 positional arguments
if [ $# -ne 4 ];then
    usage
    exit 1
fi

PRODUCT_NAME="$1"
FW_TYPE="$2"
PACKED_FILE="$3"
OUT_FILE="$4"

# Check packed firmware file exists
if [ ! -f "${PACKED_FILE}" ];then
    echo "ERROR: Firmware file [${PACKED_FILE}] does not exist"
    exit 2
fi
# Check product name max length
if [[ "${PRODUCT_NAME}" != "NA" && ${#PRODUCT_NAME} -gt ${PRODUCT_NAME_MAX_LEN} ]];then
    echo "ERROR: PRODUCT_NAME length exceed max ${PRODUCT_NAME_MAX_LEN}"
    usage
    exit 3
fi
# Check firmware type max length
if [ ${#FW_TYPE} -gt ${FW_TYPE_MAX_LEN} ];then
    echo "ERROR: FW_TYPE length exceed max ${FW_TYPE_MAX_LEN}"
    usage
    exit 4
fi

# Validate product name enum, skip validation if NA
case "$PRODUCT_NAME" in
    NA | S8630-64H | AS42-64S-AT)
        ;;
    *)
        echo "ERROR: Product name ${PRODUCT_NAME}, invalid!"
        usage
        exit 5
        ;;
esac

# Validate firmware type enum
case "$FW_TYPE" in
    BMC | BIOS | SYS_CPLD | OCM_CPLD | MISC_CPLD | PORT_CPLD1 | PORT_CPLD2 | LED_CPLD | FAN_CPLD | FPGA)
        ;;
    *)
        echo "ERROR: Firmware type ${FW_TYPE}, invalid!"
        usage
        exit 6
        ;;
esac

# Parse output directory from full out_file path
OUT_DIR=$(dirname "${OUT_FILE}")
if [[ ! -d "${OUT_DIR}" ]];then
    echo "INFO: Output directory ${OUT_DIR} not exist, try to create"
    mkdir -p "${OUT_DIR}"
fi
if [[ ! -w "${OUT_DIR}" ]];then
    echo "ERROR: Output directory [${OUT_DIR}] no write permission"
    exit 10
fi

# Pad string to 12 bytes, fill with 0x00
pad12() {
    local s="$1"
    printf "%-12s" "${s}" | tr ' ' '\0'
}
# Pad string to 16 bytes, fill with 0x00
pad16() {
    local s="$1"
    printf "%-16s" "${s}" | tr ' ' '\0'
}

TMP_FW=$(mktemp /tmp/unpack_fw.XXXXXX)
TMP_HEADER_SHA=$(mktemp /tmp/header_sha.XXXXXX)
TMP_COMPUTE_SHA=$(mktemp /tmp/compute_sha.XXXXXX)
# Clean temp file on exit / signal
trap 'rm -f "${TMP_FW}" "${TMP_HEADER_SHA}" "${TMP_COMPUTE_SHA}"' EXIT INT TERM

# Binary hex compare magic, avoid shell null-byte handling problem
MAGIC_REF=$(mktemp /tmp/magic_ref.XXXXXX)
pad12 "${MAGIC}" > "${MAGIC_REF}"
HEX_FW=$(dd if="${PACKED_FILE}" bs=1 count=${MAGIC_BYTE_LEN} skip=0 2>/dev/null | hexdump -v -e '1/1 "%02x"' | tr -d ' \n')
HEX_REF=$(hexdump -v -e '1/1 "%02x"' "${MAGIC_REF}" | tr -d ' \n')
rm -f "${MAGIC_REF}"

if [[ "${HEX_FW}" != "${HEX_REF}" ]];then
    echo "ERROR: Magic check failed!"
    echo "Firmware magic hex: ${HEX_FW}"
    echo "Expect magic hex:   ${HEX_REF}"
    exit 7
fi

# --------------------------
# Protection-1: Check file size >= meta header total length
# --------------------------
PACKED_FILE_SIZE=$(stat -c%s "${PACKED_FILE}")
if [[ ${PACKED_FILE_SIZE} -lt ${META_HEAD_TOTAL_LEN} ]];then
    echo "ERROR: File size(${PACKED_FILE_SIZE}) < meta header size(${META_HEAD_TOTAL_LEN}), truncated firmware!"
    exit 19
fi

# Read little-endian 4-bytes integer from given file offset
read_le4() {
    local off="$1"
    local b0 b1 b2 b3

    b0=$(dd if="${PACKED_FILE}" bs=1 count=1 skip=${off} 2>/dev/null|hexdump -v -e '1/1 "%u\n"')
    b1=$(dd if="${PACKED_FILE}" bs=1 count=1 skip=$((off+1)) 2>/dev/null|hexdump -v -e '1/1 "%u\n"')
    b2=$(dd if="${PACKED_FILE}" bs=1 count=1 skip=$((off+2)) 2>/dev/null|hexdump -v -e '1/1 "%u\n"')
    b3=$(dd if="${PACKED_FILE}" bs=1 count=1 skip=$((off+3)) 2>/dev/null|hexdump -v -e '1/1 "%u\n"')

    # Protection-2: detect dd read empty result (file truncated)
    if [[ -z "${b0}" || -z "${b1}" || -z "${b2}" || -z "${b3}" ]];then
        echo "ERROR: read_le4 failed! offset ${off}, file truncated / corrupted."
        exit 20
    fi

    echo $((b0 + (b1<<8)+(b2<<16)+(b3<<24)))
}

# Read firmware length from header offset 12
FW_LEN=$(read_le4 12)
echo "DBG fw_len=${FW_LEN}, total meta header len=${META_HEAD_TOTAL_LEN}"

# Sanity check firmware length
if [[ ${FW_LEN} -le 0 ]];then
    echo "ERROR: fw_len illegal value!"
    exit 8
fi

# --------------------------
# Protection-3: Check actual file size >= meta+fw_len, prevent fake fw_len
# --------------------------
EXPECT_TOTAL_SIZE=$(( META_HEAD_TOTAL_LEN + FW_LEN ))
if [[ ${PACKED_FILE_SIZE} -lt ${EXPECT_TOTAL_SIZE} ]];then
    echo "ERROR: File truncated! actual=${PACKED_FILE_SIZE}, expected=${EXPECT_TOTAL_SIZE}"
    exit 21
fi

# Extract PRODUCT_NAME from header offset 16, strip null-byte and trailing whitespace
FW_PROD=$(dd if="${PACKED_FILE}" bs=1 count=16 skip=16 2>/dev/null | tr -d '\0' | sed -e 's/[[:space:]]*$//')
# Extract FW_TYPE from header offset 32, strip null-byte and trailing whitespace
FW_FWTYPE=$(dd if="${PACKED_FILE}" bs=1 count=16 skip=32 2>/dev/null | tr -d '\0'| sed -e 's/[[:space:]]*$//')

echo "Firmware embedded info:"
echo "  PRODUCT_NAME=[${FW_PROD}]"
echo "  FW_TYPE=[${FW_FWTYPE}]"
echo "Expected info:"
if [[ "${PRODUCT_NAME}" == "NA" ]];then
    echo "  PRODUCT_NAME=[NA] (skip product name check)"
else
    echo "  PRODUCT_NAME=[${PRODUCT_NAME}]"
fi
echo "  FW_TYPE=[${FW_TYPE}]"

# Anti-stuck check
CHECK_OK=true
# Skip product name compare when argument equals NA
if [[ "${PRODUCT_NAME}" != "NA" ]];then
    if [[ "${FW_PROD}" != "${PRODUCT_NAME}" ]];then
        echo "ERROR: Anti-stuck check failed! PRODUCT_NAME mismatch!"
        CHECK_OK=false
    fi
else
    echo "INFO: PRODUCT_NAME verification is skipped(NA mode)."
fi
# FW_TYPE always must match
if [[ "${FW_FWTYPE}" != "${FW_TYPE}" ]];then
    echo "ERROR: Anti-stuck check failed! FW_TYPE mismatch!"
    CHECK_OK=false
fi

if [[ "${CHECK_OK}" != "true" ]];then
    exit 9
fi

# Extract raw firmware (skip total meta header 112 bytes)
dd if="${PACKED_FILE}" of="${TMP_FW}" bs=1 skip=${META_HEAD_TOTAL_LEN} count=${FW_LEN} 2>/dev/null

# Extract sha512_hash stored in header offset=48 , fixed 64 bytes
dd if="${PACKED_FILE}" of="${TMP_HEADER_SHA}" bs=1 skip=48 count=${SHA512_HASH_BYTES} 2>/dev/null
# Compute sha512 from extracted raw firmware
openssl dgst -sha512 -binary "${TMP_FW}" > "${TMP_COMPUTE_SHA}"

# Compare binary sha512 hash
if ! cmp -s "${TMP_HEADER_SHA}" "${TMP_COMPUTE_SHA}" ;then
    echo "ERROR: SHA512 integrity check FAILED! Firmware corrupted or modified."
    exit 12
fi
echo "INFO: SHA512 integrity check passed."
# Write result to user-specified full-path output file
cp "${TMP_FW}" "${OUT_FILE}"

echo "SUCCESS: Magic + Anti-stuck + SHA512 integrity check passed."
echo "Restored original firmware: ${OUT_FILE}"
exit 0