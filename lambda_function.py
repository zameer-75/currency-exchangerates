from bs4 import BeautifulSoup
import requests
import boto3
import datetime
import json
from boto3.dynamodb.conditions import Key  # Import Key class

# Prepare the DynamoDB client
dynamodbtablename = "currency-exchange-rates"
dynamodb = boto3.resource('dynamodb')

# Table name
table = dynamodb.Table(dynamodbtablename)

getMethod = 'GET'
exchangeratesPath = '/getexchangerates'


def lambda_handler(event, context):

    # Check if the API Gateway provided an HTTP method
    if 'httpMethod' in event:
        path = event['path']
        httpMethod = event['httpMethod']
        
        # Call the web scraping function
        scraped_data = scrape_data()

        # Insert the scraped data into DynamoDB
        insert_data_into_dynamodb(scraped_data)

        if httpMethod == getMethod and path == exchangeratesPath:
            # Get the exchange rate data from DynamoDB
            exchange_rate_data = get_exchange_rate_data()

            # Return the exchange rate data as a response
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps(exchange_rate_data)
            }
    else:
        return {
            'statusCode': 400,
            'body': 'Bad Request'
        }


def scrape_data():
    # Make an HTTP GET request to the website
    url = 'https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html'
    response = requests.get(url)
    soup = BeautifulSoup(response.content, 'html.parser')
    data = soup.find_all('tr')
    my_dict = {}
    for d in data:
        tmp1 = d.find('td', class_='currency')
        tmp2 = d.find('span', class_='rate')
        if tmp1 is not None and tmp2 is not None:
            my_dict[tmp1.text.strip()] = tmp2.text.strip()

    return my_dict


def insert_data_into_dynamodb(data):
    today = datetime.datetime.now().strftime('%Y-%m-%d')
    with table.batch_writer() as batch:
        for currency, rate in data.items():
            batch.put_item(
                Item={
                    'date': today,
                    'currency': currency,
                    'exchange_rate': rate
                }
            )


def get_exchange_rate_data():
    # Get today's date and yesterday's date
    today = datetime.datetime.now().strftime('%Y-%m-%d')
    yesterday = (datetime.datetime.now() - datetime.timedelta(days=1)).strftime('%Y-%m-%d')

    # Get exchange rate data for today and yesterday from DynamoDB
    response_today = table.scan(FilterExpression=Key('date').eq(today))
    response_yesterday = table.scan(FilterExpression=Key('date').eq(yesterday))

    exchange_rate_data = {}
    for item_today in response_today['Items']:
        currency = item_today['currency']
        exchange_rate_today = float(item_today['exchange_rate'])

        # Find the corresponding exchange rate for yesterday
        exchange_rate_yesterday = None
        for item_yesterday in response_yesterday['Items']:
            if item_yesterday['currency'] == currency:
                exchange_rate_yesterday = float(item_yesterday['exchange_rate'])
                break

        if exchange_rate_yesterday is not None:
            change = exchange_rate_today - exchange_rate_yesterday
            exchange_rate_data[currency] = {
                'current-exchange-rate': exchange_rate_today,
                'yesterday-exchange-rate': exchange_rate_yesterday,
                'change': change
            }
        else:
            # If there is no data for yesterday, exclude this currency from the response
            exchange_rate_data[currency] = {
                'current-exchange-rate': exchange_rate_today,
                'yesterday-exchange-rate': exchange_rate_yesterday,
                'change': None
            }

    return exchange_rate_data
