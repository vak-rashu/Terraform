provider aws {
    access_key = "test"
    secret_key = "test"
    region = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
}

resource "aws_api_gateway_rest_api" "api_lambda" { 
    name = "api-lambda"
    description = "My lambda API Gateway"

}

resource "aws_api_gateway_resource" "items" {
    rest_api_id = aws_api_gateway_rest_api.api_lambda.id
    parent_id = aws_api_gateway_rest_api.api_lambda.root_resource_id
    path_part = "items"
}

resource "aws_api_gateway_method" "GET"{
    rest_api_id = aws_api_gateway_rest_api.api_lambda.id
    resource_id = aws_api_gateway_resource.items.id
    http_method = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_method" "PUT"{
    rest_api_id = aws_api_gateway_rest_api.api_lambda.id
    resource_id = aws_api_gateway_resource.items.id 
    http_method = "PUT"
    authorization = "NONE"
}


resource "aws_api_gateway_resource" "byID"{
    rest_api_id = aws_api_gateway_rest_api.api_lambda.id
    parent_id = aws_api_gateway_resource.items.id
    path_part = "{id}"
}

resource "aws_api_gateway_method" "getbyID"{
    rest_api_id = aws_api_gateway_rest_api.api_lambda.id
    resource_id = aws_api_gateway_resource.byID.id 
    http_method = "GET"
    authorization = "NONE"
    request_parameters = {
        "method.request.path.id" = true
    }
}

resource "aws_api_gateway_method" "delbyID"{
    rest_api_id = aws_api_gateway_rest_api.api_lambda.id
    resource_id = aws_api_gateway_resource.byID.id 
    http_method = "DELETE"
    authorization = "NONE"
    request_parameters = {
        "method.request.path.id" = true
    }
}

resource "aws_api_gateway_integration" "get_lambda" {
    rest_api_id = aws_api_gateway_rest_api.api_lambda.id
    resource_id = aws_api_gateway_resource.items.id
    http_method = aws_api_gateway_method.GET.http_method 
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.api_lambda.invoke_arn}/invocations" 
}

resource "aws_api_gateway_integration" "put_lambda" {
    rest_api_id = aws_api_gateway_rest_api.api_lambda.id
    resource_id = aws_api_gateway_resource.items.id
    http_method = aws_api_gateway_method.PUT.http_method 
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:api-lambda/invocations"
}
resource "aws_api_gateway_integration" "get_ID_lambda" {
    rest_api_id = aws_api_gateway_rest_api.api_lambda.id
    resource_id = aws_api_gateway_resource.byID.id
    http_method = aws_api_gateway_method.getbyID.http_method 
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:api-lambda/invocations "
}

resource "aws_api_gateway_integration" "del_ID_lambda" {
    rest_api_id = aws_api_gateway_rest_api.api_lambda.id
    resource_id = aws_api_gateway_resource.byID.id
    http_method = aws_api_gateway_method.delbyID.http_method
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:api-lambda/invocations"
}


resource "aws_api_gateway_deployment" "deployment"{
    depends_on = [
        aws_api_gateway_method.GET,
        aws_api_gateway_method.PUT,
        aws_api_gateway_method.delbyID,
        aws_api_gateway_method.getbyID 
    ]
    rest_api_id = aws_api_gateway_rest_api.api_lambda.id
} 

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_lambda.id
  stage_name    = "dev"
}

output "id" {
    value = aws_api_gateway_rest_api.api_lambda.id
}
