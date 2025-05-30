#create a bucket resource
resource "aws_s3_bucket" "s3bucket"{
  bucket = "your-bucket-name"
}

#lambda iam role
resource "aws_iam_role" "lambda_exec_role" {
    name = "lambda_exec_role"

    assume_role_policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

#give that iam role permissions to access dynamodb and s3
resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["logs:*"],
        Resource = "arn:aws:logs:*:*:*",
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject"],
        Resource = "${aws_s3_bucket.s3bucket.arn}/*",
      },
      {
        Effect = "Allow",
        Action = ["dynamodb:PutItem", "dynamodb:GetItem"],
        Resource = aws_dynamodb_table.db.arn,
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn

}
#create a zip file for go
data "archive_file" "zip_file_lambda" {
  type = "zip"
  source_dir = "/path/to/lambda/lambda_function.py"
  output_path = "/path/to/lambda/function.zip"
}

#create lambda function
resource "aws_lambda_function" "lambda_func" {
  function_name = "MyProjectFunction"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler" 
  runtime       = "python3.9"                         
  filename         = "/path/to/lambda/function.zip"
  source_code_hash = filebase64sha256("/path/to/lambda/function.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.db.name
      API_ID = aws_api_gateway_rest_api.rest_api.id
      BUCKET_NAME = aws_s3_bucket.s3bucket.bucket
    }
  }
}

#creating a rest api
resource "aws_api_gateway_rest_api" "rest_api" {
  name = "myprojectAPI"
  description = "MyProject Rest API"
  binary_media_types = ["multipart/form-data"]
}

#creating the resource for shorten to post files
resource "aws_api_gateway_resource" "shorten" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part = "shorten"
}

#creating a method for the /shorten endpoint
resource "aws_api_gateway_method" "shorten_method" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id =  aws_api_gateway_resource.shorten.id
  http_method = "POST"
  authorization = "NONE"

  request_parameters = {
    "method.request.header.Content-Type" = true
    "method.request.header.Accept" = true
  }
}

#creating integration
resource "aws_api_gateway_integration" "integration_shorten" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id =  aws_api_gateway_resource.shorten.id
  http_method = aws_api_gateway_method.shorten_method.http_method
  type = "AWS_PROXY"
  integration_http_method = "POST"
  uri = aws_lambda_function.lambda_func.invoke_arn

  request_parameters = {
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
    "integration.request.header.Accept" = "method.request.header.Accept"
  }
}

resource "aws_api_gateway_resource" "short" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part = "short"
}

#alloting method to the path
resource "aws_api_gateway_method" "method" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.short.id
  http_method = "GET"
  authorization = "NONE"
}

#integrating the created api with lambda function
resource "aws_api_gateway_integration" "integration_short" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.short.id
  http_method = aws_api_gateway_method.method.http_method
  type = "AWS_PROXY"
  integration_http_method = "POST"
  uri = aws_lambda_function.lambda_func.invoke_arn
}

#make a deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [ 
    aws_api_gateway_integration.integration_shorten,
    aws_api_gateway_integration.integration_short,
   ]
   rest_api_id = aws_api_gateway_rest_api.rest_api.id  
}

#create a stage
resource "aws_api_gateway_stage" "stage" {
  stage_name = "project"
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id

}

#permission for lambda for apigw
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_func.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}

#create a dynamodb table with ttl enabled to store mapping of short code with the originalURL
resource "aws_dynamodb_table" "db" {
    name = "URLShortner"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "shortKey"
    attribute {
      name = "shortKey"
      type = "S"
    }

    ttl {
      attribute_name = "TimeToExist"
      enabled = true
    }
}

output "myprojectlink" {
  value = "https://${aws_api_gateway_rest_api.rest_api.id}.execute-api.us-east-1.amazonaws.com/${aws_api_gateway_stage.stage.stage_name}/shorten"

}
