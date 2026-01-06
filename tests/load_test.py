"""
Load testing script for API
"""
import requests
import time
import statistics
from concurrent.futures import ThreadPoolExecutor, as_completed

API_URL = "http://localhost:5000/predict"

SAMPLE_REQUESTS = [
    {"features": [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]},
    {"features": [67, 1, 0, 160, 286, 0, 0, 108, 1, 1.5, 1, 3, 2]},
    {"features": [67, 1, 0, 120, 229, 0, 0, 129, 1, 2.6, 1, 2, 3]},
    {"features": [37, 1, 2, 130, 250, 0, 1, 187, 0, 3.5, 0, 0, 2]},
]

def make_request(request_data):
    """Make a single prediction request"""
    start_time = time.time()
    try:
        response = requests.post(API_URL, json=request_data, timeout=10)
        latency = time.time() - start_time
        return {
            'success': response.status_code == 200,
            'latency': latency,
            'status_code': response.status_code
        }
    except Exception as e:
        return {
            'success': False,
            'latency': time.time() - start_time,
            'error': str(e)
        }

def run_load_test(num_requests=100, num_workers=10):
    """Run load test"""
    print(f"🚀 Starting load test: {num_requests} requests with {num_workers} workers")
    print(f"📍 Target: {API_URL}")
    print("")
    
    results = []
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=num_workers) as executor:
        # Submit requests
        futures = []
        for i in range(num_requests):
            request_data = SAMPLE_REQUESTS[i % len(SAMPLE_REQUESTS)]
            futures.append(executor.submit(make_request, request_data))
        
        # Collect results
        for future in as_completed(futures):
            results.append(future.result())
            if len(results) % 10 == 0:
                print(f"Progress: {len(results)}/{num_requests}")
    
    total_time = time.time() - start_time
    
    # Calculate statistics
    successful = sum(1 for r in results if r['success'])
    failed = len(results) - successful
    latencies = [r['latency'] for r in results if r['success']]
    
    print("\n" + "="*50)
    print("📊 LOAD TEST RESULTS")
    print("="*50)
    print(f"Total Requests:     {num_requests}")
    print(f"Successful:         {successful} ({successful/num_requests*100:.1f}%)")
    print(f"Failed:             {failed} ({failed/num_requests*100:.1f}%)")
    print(f"Total Duration:     {total_time:.2f}s")
    print(f"Requests/Second:    {num_requests/total_time:.2f}")
    print("")
    print("Latency Statistics:")
    print(f"  Min:              {min(latencies):.3f}s")
    print(f"  Max:              {max(latencies):.3f}s")
    print(f"  Mean:             {statistics.mean(latencies):.3f}s")
    print(f"  Median:           {statistics.median(latencies):.3f}s")
    if len(latencies) > 1:
        print(f"  Std Dev:          {statistics.stdev(latencies):.3f}s")
    print("="*50)

if __name__ == "__main__":
    # Run load test
    run_load_test(num_requests=100, num_workers=10)
