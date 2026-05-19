from dotenv import load_dotenv
load_dotenv() # Load variables before importing any agent modules

import sys
import os
import asyncio

# Ensure parent directory is in sys.path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from test_scenarios.test_agents import run_agent_tests
from test_scenarios.test_connection import test_api_connectivity

async def main():
    print("\n=======================================================")
    print(">>> KAAMCONNECT COMPLETE AUTOMATED TEST RUNNER <<<")
    print("=======================================================\n")
    
    # Run Agent isolated tests
    try:
        await run_agent_tests()
    except AssertionError as ae:
        print(f"\n[FAIL] Agent Test failed assertion: {ae}")
        sys.exit(1)
    except Exception as e:
        print(f"\n[FAIL] Agent Test failed with unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
        
    # Run API & WebSocket connectivity tests
    try:
        success = await test_api_connectivity()
        if not success:
            print("\n[FAIL] Connection Tests Failed. (Is your Uvicorn server running?)")
            sys.exit(1)
    except Exception as e:
        print(f"\n[FAIL] Connection Test failed with unexpected error: {e}")
        sys.exit(1)
        
    print("\n=======================================================")
    print(">>> ALL SYSTEMS 100% OPERATIONAL, EMBEDDED & STABLE! <<<")
    print("=======================================================\n")

if __name__ == "__main__":
    asyncio.run(main())
