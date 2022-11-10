import json
import pickle
import base64

model = pickle.load(open('pickle_model.pkl', 'rb'))
def handler(event, context):
    print(event)
    decode = base64.b64decode(event['body'])
    #message = decode.decode('ascii')
    data = json.loads(decode)
    input = data['input']

    result = model.predict(input)
    #print(result)
    return {
        'statusCode': 200,
        'body': json.dumps(result.tolist())
    }

#lambda_handler({"input": [[0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0]]}, {})