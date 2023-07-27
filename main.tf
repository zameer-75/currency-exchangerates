# Define the provider (AWS) and region
provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

# Create the IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "LambdaFunctionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach necessary permissions policies to the IAM role
resource "aws_iam_policy_attachment" "lambda_dynamodb_attachment" {
  name        = "LambdaDynamoDBAttachment"  
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" # Replace with the desired DynamoDB permissions
  roles      = [aws_iam_role.lambda_role.name]
}

resource "aws_iam_policy_attachment" "lambda_cloudwatch_attachment" {
  name        = "LambdaCloudWatchAttachment"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess" # Replace with the desired CloudWatch permissions
  roles      = [aws_iam_role.lambda_role.name]
}

# Create the Lambda function
resource "aws_lambda_function" "exchangerates_lambda" {
  filename      = "./exchange-rates-lambda.zip" # Replace with your Lambda function deployment package
  function_name = "ExchangeRatesLambdaFunction"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10" # Replace with your preferred runtime version
}

# Grant necessary permissions for the Lambda function to access DynamoDB
resource "aws_lambda_permission" "dynamodb_permission" {
  statement_id  = "AllowExecutionFromLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exchangerates_lambda.arn
  principal     = "dynamodb.amazonaws.com"
}

# Grant necessary permissions for the Lambda function to access CloudWatch
resource "aws_lambda_permission" "cloudwatch_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exchangerates_lambda.arn
  principal     = "logs.amazonaws.com"
}

# Grant necessary permissions for the Lambda function to access API Gateway
resource "aws_lambda_permission" "allow_api" {
  statement_id  = "AllowAPIgatewayInvokation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exchangerates_lambda.arn
  principal     = "apigateway.amazonaws.com"
}


# Create dynamodb resource

resource "aws_dynamodb_table" "currency_exchange_table" {
  name           = "currencyexchange-rates"
  billing_mode   = "PROVISIONED" # Change to "PROVISIONED" for provisioned capacity

  hash_key       = "date"
  range_key      = "currency"
  read_capacity = 5
  write_capacity = 5
  attribute {
    name = "date"
    type = "S"
  }

  attribute {
    name = "currency"
    type = "S"
  }

  tags = {
    Name = "CurrencyExchangeTable"
  }
}

# Create the IAM role for the API Gateway
resource "aws_iam_role" "api_gateway_role" {
  name = "APIGatewayLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# Attach necessary permissions policies to the IAM role
resource "aws_iam_policy_attachment" "api_gateway_lambda_attachment" {
  name        = "APIGatewayLambdaAttachment"
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  roles       = [aws_iam_role.api_gateway_role.name]
}

# Create the API Gateway
resource "aws_api_gateway_rest_api" "exchange_rates_api" {
  name = "ExchangeRatesAPI"

    endpoint_configuration {
    types = ["REGIONAL"]
  }

}

# Create a resource for the API Gateway
resource "aws_api_gateway_resource" "exchange_rates_resource" {
  rest_api_id = aws_api_gateway_rest_api.exchange_rates_api.id
  parent_id   = aws_api_gateway_rest_api.exchange_rates_api.root_resource_id
  path_part   = "getexchangerates"

}

# Create a method for the resource
resource "aws_api_gateway_method" "exchange_rates_method" {
  rest_api_id   = aws_api_gateway_rest_api.exchange_rates_api.id
  resource_id   = aws_api_gateway_resource.exchange_rates_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Create the integration with the Lambda function
resource "aws_api_gateway_integration" "exchange_rates_integration" {
  rest_api_id             = aws_api_gateway_rest_api.exchange_rates_api.id
  resource_id             = aws_api_gateway_resource.exchange_rates_resource.id
  http_method             = aws_api_gateway_method.exchange_rates_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.exchangerates_lambda.invoke_arn
}

# Create the method response
resource "aws_api_gateway_method_response" "exchange_rates_method_response" {
  rest_api_id = aws_api_gateway_rest_api.exchange_rates_api.id
  resource_id = aws_api_gateway_resource.exchange_rates_resource.id
  http_method = aws_api_gateway_method.exchange_rates_method.http_method

  status_code = "200"

  response_models = {
    "application/json" = "Empty" # Replace "Empty" with the actual model name if required
  }

}

# Create the integration response
resource "aws_api_gateway_integration_response" "exchange_rates_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.exchange_rates_api.id
  resource_id = aws_api_gateway_resource.exchange_rates_resource.id
  http_method = aws_api_gateway_method.exchange_rates_method.http_method

  status_code = aws_api_gateway_method_response.exchange_rates_method_response.status_code

  response_templates = {
    "application/json" = jsonencode({}) # No response templates needed
  }

  # Associate the integration response with the integration
  depends_on = [aws_api_gateway_integration.exchange_rates_integration]
}

# Deploy the API Gateway to a stage
resource "aws_api_gateway_deployment" "exchange_rates_deployment" {
  rest_api_id = aws_api_gateway_rest_api.exchange_rates_api.id
  stage_name  = "prod"

  # Associate the deployment with the integration response
  depends_on = [aws_api_gateway_integration_response.exchange_rates_integration_response]
}

# Output the API Gateway GET request URL
output "api_gateway_url" {
  value = "${aws_api_gateway_deployment.exchange_rates_deployment.invoke_url}/getexchangerates"
}


#Create a CloudWatch Events rule with a schedule expression to trigger the Lambda function every five minutes:

resource "aws_cloudwatch_event_rule" "lambda_trigger_rule" {
  name        = "DailyLambdaTriggerRule"
  description = "Trigger Lambda daily at 12:00 AM UTC"

  schedule_expression = "cron(0 0 * * ? *)"  # Schedule expression for daily at 12:00 AM UTC
}

# Create a Lambda function permission to allow CloudWatch Events to invoke your Lambda function:

resource "aws_lambda_permission" "cloudwatch_event_invoke" {
  statement_id  = "AllowCloudWatchInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exchangerates_lambda.arn
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.lambda_trigger_rule.arn
}

#Create a CloudWatch Events target to link the rule with your Lambda function:
resource "aws_cloudwatch_event_target" "lambda_trigger_target" {
  rule      = aws_cloudwatch_event_rule.lambda_trigger_rule.name
  target_id = "lambda_target"
  arn       = aws_lambda_function.exchangerates_lambda.arn
}

