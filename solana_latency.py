import requests
import logging
logging.basicConfig(level=logging.INFO)

rpc_urls = [
    "https://solana-rpc.publicnode.com",
    "https://api.blockeden.xyz/solana/8UuXzatAZYDBJC6YZTKD"
]
num_of_requests = 20

account_pubkeys = [
    "7xk92dHWPUXvyCYP3vsuVU4qbGso6KoCGRjwu5iR5tBh",
    "ArbT3xG9AR7kFbU78Xs5Zfxb27YBjJPgjV4n4MYUeCZQ"  
]

def get_multiple_accounts_benchmark():
    logging.info(f"Benchmarking getMultipleAccounts for {num_of_requests} requests per RPC URL.")

    for rpc_url in rpc_urls:
        logging.info(f"Benchmarking {rpc_url}")

        total_time = 0
        successful_requests = 0

        for i in range(num_of_requests):
            try:
                response = requests.post(rpc_url, json={
                    "jsonrpc": "2.0",
                    "id": "1",
                    "method": "getMultipleAccounts",
                    "params": [account_pubkeys]
                })
                response_json = response.json()

                if "result" in response_json and response_json["result"]:
                    request_time = response.elapsed.total_seconds() * 1000
                    logging.info(f"Request {i + 1} successful. Time taken: {request_time:.2f}ms")
                    total_time += request_time
                    successful_requests += 1
                else:
                    logging.warning(f"Request {i + 1} unsuccessful.")
            except Exception as e:
                logging.error(f"Request {i + 1} failed: {str(e)}")

        avg_time = total_time / successful_requests if successful_requests > 0 else 0
        logging.info(f"Benchmark for {rpc_url} completed. Average time per request: {avg_time:.2f}ms\n")

if __name__ == "__main__":
    get_multiple_accounts_benchmark()
