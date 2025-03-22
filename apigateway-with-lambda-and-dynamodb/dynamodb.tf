resource "aws_dynamodb_table" "order" {
    name = "orders"
    billing_mode = "PAY_PER_REQUEST"

    hash_key = "orderID"
    range_key = "date"

    attribute {
        name = "orderID"
        type = "S"
    } 

    attribute {
        name = "date"
        type = "S"
    }
}
