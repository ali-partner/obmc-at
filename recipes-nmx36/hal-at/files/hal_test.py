import request

def get_test():
    url = "http://127.0.0.1:8080/api/bmc/nextboot"
    response = request.get(url, verify=False)
    print(response.json())
