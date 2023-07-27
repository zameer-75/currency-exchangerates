# Currency exchange rates
This API fetches everyday exchange rates and is stored in a dynamo DB.
Here's my running API URL: ***https://lwrva1i4m6.execute-api.us-east-1.amazonaws.com/prod/getexchangerates*** 
# Lambda function (ExchangeRatesLambdaFunction)
The lambda function fetched everyday exchange rates and stored them in a database, and also exposes a public REST API endpoint that provides current exchange rate information for all tracked currencies and their change compared to the previous day for all the tracked currencies.

## Dependencies or required Packages 

1. **BeautifulSoup (from bs4 import BeautifulSoup):** BeautifulSoup is a Python library used for web scraping purposes. It provides an easy way to parse and navigate through HTML or XML documents, extract data, and extract specific elements based on tags, attributes, and class names.
In the code, BeautifulSoup is used to scrape data from a website containing exchange rate information.

2. **Requests (import requests):** Requests is a popular Python library used for making HTTP requests. It simplifies the process of sending HTTP requests to web servers and handling responses. In the code, the Requests library is used to make an HTTP GET request to a website to fetch the exchange rate data.

3. **Boto3 (import boto3):** Boto3 is the AWS SDK (Software Development Kit) for Python, which allows developers to interact with various AWS services, including DynamoDB, S3, EC2, and more. In the code, Boto3 is used to interact with the DynamoDB service to read and write data to the DynamoDB table.

4. **JSON (import json):** The JSON module in Python provides functions for working with JSON data, including serialization (converting Python objects to JSON strings) and deserialization (parsing JSON strings into Python objects). In the code, the JSON module is used to convert Python dictionaries into JSON format when returning the exchange rate data as a response from the Lambda function.

## How to install the above packages

*To install the packages mentioned in the code, you can use the Python package manager pip. First, create a folder/directory (exchange-rates-lambda) open a terminal or command prompt, and execute the following commands in the directory:*

+ BeautifulSoup: 
    ***pip install bs4 -t .***
+ Requests: ***pip install requests -t .***
+ Boto3: ***pip install boto3 -t .***
+ JSON: Python's JSON module comes built-in with Python, so you don't need to install it separately.
  
Above commands will install all the dependencies required to run the Lambda function into the folder/directory (exchange-rates-lambda). Run the command
_rm -rf *dist-info_ After running this command, we should be left with only the relevant packages needed. Now zip this folder (exchange-rates-lambda) and upload it to the Lambda function console. ***Make sure the lambda_function.py file is presented in the same directory***

**To Trigger Lambda Function Manually from the console make sure you have set the following Event Json**
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/e63caf6a-c1e6-45ca-9148-7bdea2c442e5)

**On Successful function run you will see the following output**
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/758f72d9-faaa-4bd4-8870-621df8202485)

***Please note that we are seeing null values for yesterday's data and change rate because these value has not yet been added to DynamoDB table***

## Following AWS Services have been used to accomplish this task.

+ #### DynamoDB Table Create DynamoDB Table (currencyexchange-rates) and set the date as a partition Key.
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/55aaec32-c59e-4175-b07c-5e0543529cdc)

+ #### Create IAM Roles that the Lambda function can use to communicate with DynamoDB, API Gateway, and Cloudwatch
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/7ddecf07-3047-417b-b7be-9bd29bbb4025)

![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/25f0457c-7fe2-4852-b732-29d3c830bcbc)

![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/a234c642-dc9f-4776-9329-ed1387c324fd)

+ #### AWS Lambda Function (ExchangeRatesLambdaFunction)
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/1ed7cac9-311f-47fa-8f17-381f96dad2d4)

+ #### Cloudwatch Trigger to execute Lambda function every day  
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/127428c8-339d-4c76-960a-7afef70260c4)

+ #### AWS API Gateway (ExchangeRatesAPI)
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/33d6410e-6bf7-4c27-890e-f38be8e7778e)

![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/eaf114d3-f0f0-4302-bd83-95cb1b33b8fe)

+ #### AWS CloudWatch:
Set up AWS CloudWatch to monitor the Lambda functions and API Gateway for errors and performance metrics.

## How to Deploy this application using IaC Framework (Terraform)
1. Clone the Repo https://github.com/zameer-75/currency-exchangerates.git
2. **Make sure you have the following Prerequisite setups**
   + The ***Terraform CLI (1.2.0+)*** installed.
   + The ***AWS CLI*** installed.
   + ***AWS account and associated credentials*** that allow you to create resources.    
3. Open the terminal and move into the repo OR open the Repo in VS code
4. Run the following commands
   + terraform init
   + terraform validate
   + terraform plan
   + terraform apply
5. It will automatically deploy the application to AWS and will show the API Gateway URL:
    ***https://lwrva1i4m6.execute-api.us-east-1.amazonaws.com/prod/getexchangerates*** 
7.  Final output will be as follow
      ![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/1b2e11b6-f5a7-485c-ad43-502edfb9f65f)

8.  When we access the API Gateway URL using Postman we got the following results (***if we have two days of data stored in DynamoDB***)
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/73004f45-1bb8-47ed-b353-2cf54da80c8c)

9.  ***Please note that after fresh installation you will see null values for ***yesterday's and change rate*** because these values have not yet been added to the DynamoDB table, they will be added when the Lambda function will trigger next day as per the following assignment note***
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/c5bf64ca-b0c6-43bb-a1f5-25b9ebb7d79d)

10.  To destroy this application, run the command ***terraform destroy***
