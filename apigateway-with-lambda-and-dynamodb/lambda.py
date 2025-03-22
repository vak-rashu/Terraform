import json
import boto3

client = boto3.client('dynamodb')
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table('orders')

def handler(event, context):
    body = {}
    status_code = 200
    headers = {
        "Content-Type": "application/json"
    }

    try:
        http_method = event["httpMethod"]
        resource = event["resource"]  # Use "resource" instead of "path"

        # GET /items - Fetch all orders
        if http_method == "GET" and resource == "/items":
            response = table.scan()
            body = response.get("Items", [])

        # PUT /items - Create a new order
        elif http_method == "PUT" and resource == "/items":
            request_json = json.loads(event['body'])

            table.put_item(
                Item={
                    'orderID': request_json['orderID'],
                    'date': request_json['date'],
                    'order': request_json['order']
                }
            )
            body = {"message": "Order added successfully"}

        # GET /items/{id} - Fetch a specific order
        elif http_method == "GET" and resource == "/items/{id}":
            order_id = event["pathParameters"]["id"]  # Use "id" instead of "orderID"
            response = table.get_item(Key={"orderID": order_id})

            if "Item" in response:
                body = response["Item"]
            else:
                status_code = 404 
                body = {"error": "Order not found"}

        # DELETE /items/{id} - Delete a specific order
        elif http_method == "DELETE" and resource == "/items/{id}":
            order_id = event["pathParameters"]["id"]
            table.delete_item(Key={"orderID": order_id})
            body = {"message": f"Deleted order {order_id}"}

        else:
            status_code = 400
            body = {"error": "Invalid request"}

    except Exception as e:
        status_code = 500
        body = {"error": f"Error occurred: {str(e)}"}

    return {
        "statusCode": status_code,
        "body": json.dumps(body),
        "headers": headers
    }
