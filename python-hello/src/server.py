"""Example of Flask."""
from flask import Flask, jsonify, request
app = Flask(__name__)


@app.route('/hello', methods=['GET'])
def hello():
    """Say hello."""
    if request.method == 'GET':
        data = {"message": "Hello, world!"}
        return jsonify(data)


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=8080)
