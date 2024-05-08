

## Employee Database Application

This is a simple python application to interact with an Employee database. I used flask and SQLAlchemy to connect to a local postgres database. I followed [Parwiz Forogh's tutorial](https://www.youtube.com/watch?v=XTpLbBJTOM4&t=2779s)

### Requirements
- Python 3.12.2

### To run project
- Clone repository
- Create virtual environment in project root
- Activate virtual environment 
- Install requirements from `requirements.txt` with `pip install -r requirements.txt`
- Update `DATABASE_URI` in `configuration.py` to your own desired URI
- Create database with desired name
- In terminal, run `flask shell` then `db.create_all()` to create the Data table
