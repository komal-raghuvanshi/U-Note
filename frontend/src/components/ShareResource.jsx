
import { useState } from 'react'

function ShareResource({ onBack }) {
  const [submitted, setSubmitted] = useState(false)
  const [file, setFile] = useState(null)
  const [error, setError] = useState('')
  const [uploading, setUploading] = useState(false)

  const [formData, setFormData] = useState({
    title: '',
    branch: '',
    semester: '',
    subject: '',
    unit: '',
    type: ''
  })

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    setError('')

    if (!file) {
      setError('Please select a file.')
      return
    }

    const data = new FormData()
    data.append('file', file)

    try {
      setUploading(true)

      const response = await fetch(
        'http://127.0.0.1:5000/resources/upload',
        {
          method: 'POST',
          body: data
        }
      )

      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.message || 'Upload failed.')
      }

      setSubmitted(true)
    } catch (err) {
      setError(err.message || 'Unable to upload file.')
    } finally {
      setUploading(false)
    }
  }

  return (
    <div className="share-page-container">
      <div className="section-container">
        <div className="share-form-wrapper">
          <div className="share-form-header">
            <button
              type="button"
              className="back-link-btn"
              onClick={onBack}
            >
              &larr; Back to Home
            </button>

            <h1 className="share-form-title">
              Share a Study Resource
            </h1>

            <p className="share-form-subtitle">
              Contribute verified study material to help your fellow RGPV students.
            </p>
          </div>

          {submitted ? (
            <div className="submission-success-card">
              <h3>File Uploaded Successfully!</h3>

              <p>
                <strong>{formData.title}</strong> ({formData.type}) for{' '}
                {formData.branch} Semester {formData.semester}.
              </p>

              <p className="success-note">
                Your file has been uploaded to the backend.
                Resource details are not yet saved to the database.
              </p>

              <div className="success-actions">
                <button
                  type="button"
                  className="btn btn-primary"
                  onClick={onBack}
                >
                  Return to Home
                </button>

                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => {
                    setSubmitted(false)
                    setFile(null)
                    setError('')
                    setFormData({
                      title: '',
                      branch: '',
                      semester: '',
                      subject: '',
                      unit: '',
                      type: ''
                    })
                  }}
                >
                  Share Another
                </button>
              </div>
            </div>
          ) : (
            <form
              className="share-resource-form"
              onSubmit={handleSubmit}
            >
              <div className="form-group">
                <label htmlFor="title">Resource Title</label>
                <input
                  type="text"
                  id="title"
                  name="title"
                  className="form-control"
                  placeholder="e.g. Unit 1 Complete Handwritten Notes"
                  value={formData.title}
                  onChange={handleChange}
                  required
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="branch">Branch</label>
                  <select
                    id="branch"
                    name="branch"
                    className="form-control"
                    value={formData.branch}
                    onChange={handleChange}
                    required
                  >
                    <option value="" disabled>Select branch</option>
                    <option value="AIML">AIML</option>
                    <option value="CSE">CSE</option>
                    <option value="IT">IT</option>
                    <option value="EC">EC</option>
                    <option value="ME">ME</option>
                    <option value="Civil">Civil</option>
                  </select>
                </div>

                <div className="form-group">
                  <label htmlFor="semester">Semester</label>
                  <select
                    id="semester"
                    name="semester"
                    className="form-control"
                    value={formData.semester}
                    onChange={handleChange}
                    required
                  >
                    <option value="" disabled>Select semester</option>
                    {[1, 2, 3, 4, 5, 6, 7, 8].map((sem) => (
                      <option key={sem} value={sem}>
                        Semester {sem}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="subject">Subject Name</label>
                  <input
                    type="text"
                    id="subject"
                    name="subject"
                    className="form-control"
                    placeholder="e.g. Machine Learning"
                    value={formData.subject}
                    onChange={handleChange}
                    required
                  />
                </div>

                <div className="form-group">
                  <label htmlFor="unit">Unit</label>
                  <select
                    id="unit"
                    name="unit"
                    className="form-control"
                    value={formData.unit}
                    onChange={handleChange}
                    required
                  >
                    <option value="" disabled>Select unit</option>
                    {[1, 2, 3, 4, 5].map((u) => (
                      <option key={u} value={u}>
                        Unit {u}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="form-group">
                <label htmlFor="type">Resource Type</label>
                <select
                  id="type"
                  name="type"
                  className="form-control"
                  value={formData.type}
                  onChange={handleChange}
                  required
                >
                  <option value="" disabled>Select resource type</option>
                  <option value="Handwritten Notes">Handwritten Notes</option>
                  <option value="PDF Notes">PDF Notes</option>
                  <option value="Class Notes">Class Notes</option>
                  <option value="Previous Year Papers">Previous Year Papers</option>
                  <option value="Important Questions">Important Questions</option>
                  <option value="YouTube Lectures">YouTube Lectures</option>
                  <option value="Teacher Resources">Teacher Resources</option>
                </select>
              </div>

              <div className="form-group">
                <label htmlFor="file">Select File (PDF, PNG, JPG, JPEG)</label>
                <input
                  type="file"
                  id="file"
                  name="file"
                  className="form-control file-input"
                  accept=".pdf,.png,.jpg,.jpeg"
                  onChange={(e) => setFile(e.target.files[0] || null)}
                  required
                />
              </div>

              {error && (
                <p className="error-message" role="alert">
                  {error}
                </p>
              )}

              <div className="form-button-row">
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={uploading}
                >
                  {uploading ? 'Uploading...' : 'Submit Resource'}
                </button>

                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={onBack}
                  disabled={uploading}
                >
                  Cancel
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  )
}

export default ShareResource
