from flask import Flask, render_template, request, redirect
import sqlite3

app = Flask(__name__)

def get_db_connection():
    connection = sqlite3.connect("patients.db")
    connection.row_factory = sqlite3.Row
    return connection

def create_table():
    connection = get_db_connection()
    connection.execute("""
        CREATE TABLE IF NOT EXISTS patients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER NOT NULL
            )
        """)
    connection.commit()
    connection.close()

@app.route("/")
def home():
    connection = get_db_connection()    
    patients = connection.execute(
        "SELECT * FROM patients"
    ).fetchall()
    connection.close()

    return render_template("index.html", patients=patients)

@app.route("/add-patient", methods = ["POST"])

def add_patient():
    name = request.form["name"].strip()
    age = request.form["age"]

    if not name or not age or not age.isdigit():
        return "Invalid patient details", 400

    connection = get_db_connection()
    connection.execute(
        "INSERT INTO patients (name, age) VALUES (?,?)",
        (name, int(age))
    )
    connection.commit()
    connection.close()

    return redirect("/")

@app.route("/patient/<int:patient_id>")
def patient_details(patient_id):
    connection = get_db_connection()

    patient = connection.execute(
        "SELECT * FROM patients WHERE id=?",
        (patient_id,)
    ).fetchone()

    connection.close()

    if patient is None:
        return "Patient not found", 404

    return render_template(
        "patient_details.html",
        patient=patient
    )

if __name__ == "__main__":
    create_table()
    app.run(debug = True)