import asyncio
import websockets
import json

async def test_chat():
    booking_id = "test_booking_123"
    uri_customer = f"ws://localhost:8000/ws/chat/{booking_id}/customer_faiq"
    uri_provider = f"ws://localhost:8000/ws/chat/{booking_id}/provider_ali"

    print("=== Testing Real-Time In-App Chat ===")
    
    try:
        # Connect both customer and provider to the same booking chat room
        async with websockets.connect(uri_customer) as ws_cust, websockets.connect(uri_provider) as ws_prov:
            print("[CONNECTED] Customer connected to room.")
            print("[CONNECTED] Provider connected to room.")

            # Read the joining broadcast message on both sides
            msg_cust_join = await ws_cust.recv()
            print("Customer received join confirmation:", json.loads(msg_cust_join))

            # Since provider joined second, customer receives provider's join message
            msg_cust_recv_prov_join = await ws_cust.recv()
            print("Customer received provider join alert:", json.loads(msg_cust_recv_prov_join))

            # Provider receives its own join message
            msg_prov_join = await ws_prov.recv()
            print("Provider received join confirmation:", json.loads(msg_prov_join))

            # 1. Customer sends a message
            chat_msg_from_customer = {"text": "Assalam-o-Alaikum Ali, kab tak pohnchein gay?"}
            await ws_cust.send(json.dumps(chat_msg_from_customer))
            print("\n[SEND] Customer sent: 'Assalam-o-Alaikum Ali, kab tak pohnchein gay?'")

            # Customer receives their own message reflection
            cust_reflection = await ws_cust.recv()
            print("Customer received reflection:", json.loads(cust_reflection))

            # Provider receives customer's message
            prov_recv = await ws_prov.recv()
            print("[RECEIVE] Provider received message:", json.loads(prov_recv))

            # 2. Provider replies
            chat_reply_from_provider = {"text": "Walaikum Assalam, mein 10 mins mein G-13 pohnch raha hoon."}
            await ws_prov.send(json.dumps(chat_reply_from_provider))
            print("\n[SEND] Provider replied: 'Walaikum Assalam, mein 10 mins mein G-13 pohnch raha hoon.'")

            # Provider receives their own message reflection
            prov_reflection = await ws_prov.recv()
            print("Provider received reflection:", json.loads(prov_reflection))

            # Customer receives provider's reply
            cust_recv = await ws_cust.recv()
            print("[RECEIVE] Customer received reply:", json.loads(cust_recv))

        print("\n[SUCCESS] WebSocket In-App Chat test completed successfully!")
    except Exception as e:
        print("\n[FAILED] WebSocket In-App Chat test failed:", e)

if __name__ == "__main__":
    asyncio.run(test_chat())
