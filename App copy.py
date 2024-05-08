import threading
import time
from flask import Flask, render_template, request, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
import psycopg2
import os
import hvac
from sqlalchemy import create_engine
from configuration import DATABASE_URI
import yaml

app = Flask(__name__)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# PATH = 'database/creds/admin-role'
PATH = 'database/creds/read-only'

def get_database_credentials():
    client = hvac.Client(
        url=os.environ.get("VAULT_ADDR"),
        token=os.environ.get("VAULT_TOKEN"),
    )
    response = client.read(PATH)
    if response and 'data' in response:
        secret_data = response['data']
        username = secret_data['username']
        password = secret_data['password']
        print(f"User: {username}, Password:  {password}")
    
    return response["data"]["username"], response["data"]["password"]

def get_database_uri():
    username, password = get_database_credentials()
    database_uri = f'postgresql://{username}:{password}@localhost:5432/HashiCorpDemo'
    return database_uri

app.secret_key = "secret key"

app.config['SQLALCHEMY_DATABASE_URI'] = get_database_uri() 

db = SQLAlchemy(app)

class Data(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100))
    price = db.Column(db.Integer)


    def __init__(self, name, price):
        self.name = name
        self.price = price


@app.route('/')
def Index():
    get_database_uri()
    all_data = Data.query.all()
    all_data.sort(key=lambda x: x.id)
    return render_template("index.html", applications=all_data)

@app.route('/insert', methods = ['POST'])
def insert():
    get_database_uri()
    if request.method == 'POST':

        name = request.form['name']
        price = request.form['price']

        my_data = Data(name, price)
        db.session.add(my_data)
        db.session.commit()

        flash("Application Inserted Succesfully")

        return redirect(url_for('Index'))

@app.route('/update', methods=['GET', 'POST'])
def update():
    get_database_uri()

    if request.method == 'POST':
        my_data = Data.query.get(request.form.get('id'))

        my_data.name = request.form['name']
        my_data.price = request.form['price']

        db.session.commit()
        flash("Application Updated Successfully")
        return redirect(url_for('Index'))

@app.route('/delete/<id>/', methods=['GET', 'POST'])
def delete(id):
    get_database_uri()

    my_data = Data.query.get(id)
    db.session.delete(my_data)
    db.session.commit()
    flash("Application Deleted Successfully")

    return redirect(url_for('Index'))


if __name__=="__main__":

    app.run(debug=True)