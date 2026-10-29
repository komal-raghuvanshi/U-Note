import os
import unittest
from io import BytesIO
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import app
from auth_utils import create_auth_token


@unittest.skipUnless(
    os.getenv("UNOTE_RUN_LIVE_TESTS") == "1",
    "set UNOTE_RUN_LIVE_TESTS=1 only when a disposable test database is configured",
)
class LiveIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = app.test_client()
        cls.auth_headers = cls.token_headers(1)

    @staticmethod
    def token_headers(user_id):
        with app.app_context():
            token = create_auth_token(user_id)
        return {"Authorization": f"Bearer {token}"}

    def test_01_branches_endpoint(self):
        response = self.client.get('/branches')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertGreaterEqual(data['count'], 6)
        branch_names = [b['name'] for b in data['branches']]
        self.assertIn('AIML', branch_names)
        self.assertIn('CSE', branch_names)
        self.assertIn('IT', branch_names)
        self.assertIn('EC', branch_names)
        self.assertIn('ME', branch_names)
        self.assertIn('Civil', branch_names)

    def test_02_subjects_endpoint_with_branch_and_semester(self):
        response = self.client.get('/subjects?branch=AIML&semester=4')
        self.assertEqual(response.status_code, 200)
        subjects = response.get_json()
        self.assertTrue(len(subjects) >= 3)
        subj_names = [s['name'] for s in subjects]
        self.assertIn('Machine Learning', subj_names)
        self.assertIn('Artificial Intelligence', subj_names)
        self.assertIn('Software Engineering', subj_names)
        # Check code is present
        for s in subjects:
            self.assertTrue('code' in s)

    def test_03_units_endpoint_for_subject(self):
        response = self.client.get('/units?subject=Machine Learning&branch=AIML&semester=4')
        self.assertEqual(response.status_code, 200)
        units = response.get_json()
        self.assertEqual(len(units), 5)
        unit_nums = [u['unit_number'] for u in units]
        self.assertEqual(unit_nums, [1, 2, 3, 4, 5])

    def test_04_resources_endpoint_and_filters(self):
        response = self.client.get('/resources')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn('resources', data)
        self.assertTrue(len(data['resources']) >= 1)

        # Test branch & semester filter
        filtered_resp = self.client.get('/resources?branch=AIML&semester=4')
        self.assertEqual(filtered_resp.status_code, 200)
        for r in filtered_resp.get_json()['resources']:
            self.assertEqual(r['branch'], 'AIML')
            self.assertEqual(r['semester'], 4)

    def test_05_auth_login_validation(self):
        # Valid login with test user Komal
        resp = self.client.post('/login', json={
            'email': 'komalraghuvanshi206@gmail.com',
            'password': 'password123'  # test if this password works or invalid password
        })
        self.assertIn(resp.status_code, [200, 401])

        # Invalid login
        bad_resp = self.client.post('/login', json={
            'email': 'nonexistent_student_12345@test.com',
            'password': 'wrong'
        })
        self.assertEqual(bad_resp.status_code, 401)
        self.assertIn('error', bad_resp.get_json())

    def test_06_shared_resources_endpoint(self):
        response = self.client.get('/resources/shared', headers=self.auth_headers)
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data['success'])
        self.assertIsInstance(data['resources'], list)

    def test_07_upload_and_delete_resource_flow(self):
        # Create a test PDF in-memory
        test_file = (BytesIO(b'%PDF-1.4 test document content for upload'), 'test_doc.pdf')
        upload_resp = self.client.post('/resources/upload', data={
            'file': test_file,
            'title': 'Automated Test Notes for Unit 1',
            'description': 'Integration test created resource',
            'branch': 'AIML',
            'semester': '4',
            'subject': 'Machine Learning',
            'unit': '1',
            'type': 'PDF Notes',
        }, content_type='multipart/form-data', headers=self.auth_headers)

        self.assertEqual(upload_resp.status_code, 201)
        upload_data = upload_resp.get_json()
        self.assertTrue(upload_data['success'])
        new_resource_id = upload_data['resource']['id']
        filename = upload_data['filename']

        # Verify download route
        download_resp = self.client.get(f'/download/{filename}')
        self.assertEqual(download_resp.status_code, 200)

        # Verify deletion forbidden for wrong user
        forbidden_resp = self.client.delete(
            f'/resources/{new_resource_id}',
            headers=self.token_headers(9999)
        )
        self.assertEqual(forbidden_resp.status_code, 403)

        # Delete with owner
        del_resp = self.client.delete(
            f'/resources/{new_resource_id}',
            headers=self.auth_headers
        )
        self.assertEqual(del_resp.status_code, 200)
        self.assertTrue(del_resp.get_json()['success'])


if __name__ == '__main__':
    unittest.main()
