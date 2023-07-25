# Currency exchange rates
This API fetches everyday exchange rates and is stored in a dynamo DB.

# Lambda function 
The lambda function fetched everyday exchange rates and stored them in a database, and also exposes a public REST API endpoint that provides current exchange rate information for all tracked currencies and their change compared to the previous day for all the tracked currencies.

## Dependencies or required Packages 

1. **BeautifulSoup (from bs4 import BeautifulSoup):** BeautifulSoup is a Python library used for web scraping purposes. It provides an easy way to parse and navigate through HTML or XML documents, extract data, and extract specific elements based on tags, attributes, and class names.
In the code, BeautifulSoup is used to scrape data from a website containing exchange rate information.

2. **Requests (import requests):** Requests is a popular Python library used for making HTTP requests. It simplifies the process of sending HTTP requests to web servers and handling responses. In the code, the Requests library is used to make an HTTP GET request to a website to fetch the exchange rate data.

3. **Boto3 (import boto3):** Boto3 is the AWS SDK (Software Development Kit) for Python, which allows developers to interact with various AWS services, including DynamoDB, S3, EC2, and more. In the code, Boto3 is used to interact with the DynamoDB service to read and write data to the DynamoDB table.

4. **JSON (import json):** The JSON module in Python provides functions for working with JSON data, including serialization (converting Python objects to JSON strings) and deserialization (parsing JSON strings into Python objects). In the code, the JSON module is used to convert Python dictionaries into JSON format when returning the exchange rate data as a response from the Lambda function.

## How to install the above packages

*To install the packages mentioned in the code, you can use the Python package manager pip. First, create a folder/directory (require-packages) open a terminal or command prompt, and execute the following commands in the directory:*

+ BeautifulSoup: 
    ***pip install bs4 -t .***
+ Requests: ***pip install requests -t .***
+ Boto3: ***pip install boto3 -t .***
+ JSON: Python's JSON module comes built-in with Python, so you don't need to install it separately.
Above commands will install all the dependencies required to run the Lambda function into the folder/directory (require-packages). Run the command
_rm -rf *dist-info_ After running this command, we should be left with only the relevant packages needed. Now zip this folder (require-packages) and upload and add it to the Lambda function layer.

## AWS Services 

###  DynamoDB Table (currency-exchange-rates)
Create DynamoDB Table (currency-exchange-rates) and set currency as a partition Key.

### Create S3 bucket 

1. Create an S3 bucket (currency-exchangerate-bucket) and upload the required packages to the S3 bucket and grant it to the public access so that it can be easily accessible.
2.  S3 Object URL: https://currency-exchangerate-bucket.s3.amazonaws.com/requiredpython-packages.zip 

### Create IAM Role that the Lambda function can use to communicate with DynamoDB and Cloudwatch

### AWS Lambda Function

1. Create a new Lambda function and *attached the IAM role (currency-exchange-role)*
2. Add a new layer to the Lambda function and upload the required packages zip file to the layer from S3 endpoint https://currency-exchangerate-bucket.s3.amazonaws.com/requiredpython-packages.zip. 
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/0bdd5f7c-f727-467b-846d-7cc1766a7681)

3. Add this Layer to the Lambda function
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/72d5fb46-283a-4006-96b6-9bc9f94b00b6)

4. Configure the Test Event for the Lambda function
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/074400fa-be9f-4bed-93f8-b6d987c67c81)

5. Now Deploy and test the Lambda function it will return a JSON response

### Cloudwatch Trigger to execute Lambda function every day  
1. Create EventBridge Schedule to trigger the lambda function every day using a cron job
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/2c167995-bc15-4c11-80d6-d48aba3901a7)

2. Added target to the Lambda Function
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/b1844456-976b-4d5c-b413-c3133b733e30)

### AWS API Gateway 

1. Create API Gateway and select REST API
2. Create Resources (getexchangerates) and Methods (Get) for API Gateway
![image](https://github.com/zameer-75/currency-exchangerates/assets/139122254/d96e5764-99fd-4482-b9b4-a03dd511fced)

3. Create and Deploy it to the stage (prod).
4. It will create an Invoke URL: https://q9d3bfnz80.execute-api.us-east-1.amazonaws.com/prod/getexchangerates

### AWS CloudWatch:
Set up AWS CloudWatch to monitor the Lambda functions and API Gateway for errors and performance metrics.
  
