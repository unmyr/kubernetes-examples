"""Example of Flask."""
from flask import Flask, jsonify, request

app = Flask(__name__)


@app.route('/api/greet/<name>', methods=['GET'])
def greet(name: str):
    """Say hello."""
    if request.method == 'GET':
        data = {"message": f"Hello, {name}!"}
        return jsonify(data)

# if __name__ == '__main__':
#     app.run(debug=True, host="0.0.0.0",port=8080)
