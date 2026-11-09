import unittest
from unittest.mock import MagicMock, patch

from flask import Flask

from backend.auth_utils import create_auth_token
from backend.routes import auth, branches, subjects


class AcademicRouteTests(unittest.TestCase):
    def setUp(self):
        self.app = Flask(__name__)
        self.app.config["SECRET_KEY"] = "academic-route-test-secret"
        self.app.register_blueprint(branches.branches_bp)
        self.app.register_blueprint(subjects.subjects_bp)
        self.app.register_blueprint(auth.auth_bp)
        self.client = self.app.test_client()

    def test_semesters_are_limited_to_the_selected_branch(self):
        cursor = MagicMock()
        cursor.fetchall.return_value = [
            {"id": 1, "name": "Semester 1", "number": 1, "branch": "DS"},
            {"id": 2, "name": "Semester 2", "number": 2, "branch": "DS"},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(branches, "get_db_connection", return_value=connection):
            response = self.client.get("/semesters?branch=DS")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["count"], 2)
        query, parameters = cursor.execute.call_args.args
        self.assertIn("WHERE LOWER(b.branch_name) = LOWER(%s)", query)
        self.assertEqual(parameters, ("DS",))

    def test_semesters_require_a_selected_branch(self):
        with patch.object(branches, "get_db_connection") as get_connection:
            response = self.client.get("/semesters")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), {"count": 0, "semesters": []})
        get_connection.assert_not_called()

    def test_subjects_include_catalogue_classification_and_respect_filters(self):
        cursor = MagicMock()
        cursor.fetchall.return_value = [{
            "id": 32,
            "code": "AL-304",
            "name": "Artificial Intelligence",
            "branch": "AIML",
            "semester": "Semester 3",
            "category": "Compulsory Theory",
            "elective_group": None,
            "is_selectable": 1,
            "is_provisional": 0,
        }]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(subjects, "get_db_connection", return_value=connection):
            response = self.client.get("/subjects?branch=AIML&semester=3")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()[0]["code"], "AL-304")
        self.assertEqual(response.get_json()[0]["category"], "Compulsory Theory")
        query, parameters = cursor.execute.call_args.args
        self.assertIn("LEFT JOIN subject_catalogue_metadata", query)
        self.assertEqual(tuple(parameters), ("AIML", "Semester 3"))

    def test_units_are_scoped_to_the_selected_subject_branch_and_semester(self):
        cursor = MagicMock()
        cursor.fetchall.return_value = [{
            "id": 13,
            "unit_number": 1,
            "name": "Introduction",
            "subject_id": 2,
            "subject_name": "Machine Learning",
            "subject_code": "AIML402",
        }]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(subjects, "get_db_connection", return_value=connection):
            response = self.client.get(
                "/units?subject=Machine%20Learning&branch=AIML&semester=4"
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            [(unit["subject_id"], unit["unit_number"]) for unit in response.get_json()],
            [(2, 1)],
        )
        query, parameters = cursor.execute.call_args.args
        self.assertIn("JOIN subjects s ON u.subject_id = s.subject_id", query)
        self.assertIn("LOWER(s.subject_name) = LOWER(%s)", query)
        self.assertIn("LOWER(b.branch_name) = LOWER(%s)", query)
        self.assertIn("sem.semester_name = %s", query)
        self.assertEqual(
            tuple(parameters),
            ("Machine Learning", "Machine Learning", "AIML", "Semester 4"),
        )

    def test_signup_accepts_a_ds_semester_from_the_database(self):
        cursor = MagicMock()
        cursor.lastrowid = 501
        cursor.fetchone.side_effect = [
            None,
            {
                "branch_id": 7,
                "semester_id": 52,
                "semester_name": "Semester 3",
                "branch_name": "DS",
            },
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection):
            response = self.client.post("/signup", json={
                "name": "DS Student",
                "email": "ds-student@example.com",
                "password": "valid-password",
                "branch": "DS",
                "semester": 3,
            })

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.get_json()["user"]["branch"], "DS")
        self.assertEqual(response.get_json()["user"]["semester"], 3)
        self.assertTrue(connection.commit.called)

    def test_profile_update_accepts_a_ds_semester_from_the_database(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {"role": "student"},
            {"branch_id": 7, "semester_id": 52},
            {
                "user_id": 501,
                "name": "DS Student",
                "email": "ds-student@example.com",
                "role": "student",
                "branch": "DS",
                "semester": "Semester 3",
            },
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor
        with self.app.app_context():
            token = create_auth_token(501)

        with patch.object(auth, "get_db_connection", return_value=connection):
            response = self.client.put(
                "/profile",
                json={"name": "DS Student", "branch": "DS", "semester": 3},
                headers={"Authorization": f"Bearer {token}"},
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["user"]["branch"], "DS")
        self.assertEqual(response.get_json()["user"]["semester"], 3)
        update_query, update_values = cursor.execute.call_args_list[1].args
        self.assertIn("FROM branches b", update_query)
        self.assertEqual(update_values, ("DS", "Semester 3"))



    def test_subjects_fallback_when_catalogue_metadata_table_is_missing(self):
        cursor = MagicMock()
        cursor.fetchall.return_value = [{
            "id": 1,
            "code": "AIML401",
            "name": "Artificial Intelligence",
            "branch": "AIML",
            "semester": "Semester 4",
            "category": None,
            "elective_group": None,
            "is_selectable": 1,
            "is_provisional": 0,
        }]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with (
            patch.object(subjects, "get_db_connection", return_value=connection),
            patch.object(subjects, "table_exists", return_value=False),
        ):
            response = self.client.get("/subjects?branch=AIML&semester=4")

        self.assertEqual(response.status_code, 200)
        subjects_data = response.get_json()
        self.assertEqual(len(subjects_data), 1)
        self.assertEqual(subjects_data[0]["name"], "Artificial Intelligence")
        query, _ = cursor.execute.call_args.args
        self.assertNotIn("subject_catalogue_metadata", query)

    def test_subject_by_id_fallback_when_catalogue_metadata_table_is_missing(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "id": 1,
            "code": "AIML401",
            "name": "Artificial Intelligence",
            "branch": "AIML",
            "semester": "Semester 4",
            "category": None,
            "elective_group": None,
            "is_selectable": 1,
            "is_provisional": 0,
        }
        cursor.fetchall.return_value = [
            {"id": 10, "unit_number": 1, "name": "Introduction"}
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with (
            patch.object(subjects, "get_db_connection", return_value=connection),
            patch.object(subjects, "table_exists", return_value=False),
        ):
            response = self.client.get("/subjects/1")

        self.assertEqual(response.status_code, 200)
        subject_data = response.get_json()
        self.assertEqual(subject_data["name"], "Artificial Intelligence")
        self.assertEqual(len(subject_data["units"]), 1)
        first_query = cursor.execute.call_args_list[0].args[0]
        self.assertNotIn("subject_catalogue_metadata", first_query)


if __name__ == "__main__":
    unittest.main()
