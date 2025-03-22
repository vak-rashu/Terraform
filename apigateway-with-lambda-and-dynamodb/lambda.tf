resource "aws_lambda_function" "api_lambda" {
    function_name = "lambda-api"
    filename = "function.zip"
    runtime = "python3.12"
    role = "arn:aws:iam::000000000000:role/lamabda-role"
    handler = "lambda.handler"
}
