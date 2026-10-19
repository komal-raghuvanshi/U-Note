import { useState } from 'react'

function ShareResource({ onBack }) {
  const [submitted, setSubmitted] = useState(false)
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

  const handleSubmit = (event) => {
    event.preventDefault()
    setSubmitted(true)
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
            <h1 className="share-form-title">Share a Study Resource</h1>
            <p className="share-form-subtitle">
              Contribute verified study material to help your fellow RGPV students.
            </p>
          </div>

          <div className="prototype-badge-box">
            <span className="prototype-badge-pill">UI Prototype</span>
            <p className="prototype-badge-text">
              File upload backend integration is currently in progress. Submissions on this form are preview-only.
            </p>
          </div>

          {submitted ? (
            <div className="submission-success-card">
              <h3>Resource Preview Submitted!</h3>
              <p>
                <strong>{formData.title}</strong> ({formData.type}) for {formData.branch} Semester {formData.semester}.
              </p>
              <p className="success-note">
                Once backend upload integration is finalized, your upload will be saved to the database.
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
                  onClick={() => setSubmitted(false)}
                >
                  Share Another
                </button>
              </div>
            </div>
          ) : (
            <form className="share-resource-form" onSubmit={handleSubmit}>
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
                <label htmlFor="file">Select File (PDF, DOC, Images)</label>
                <input
                  type="file"
                  id="file"
                  name="file"
                  className="form-control file-input"
                  accept=".pdf,.doc,.docx,.jpg,.jpeg,.png"
                  required
                />
              </div>

              <div className="form-button-row">
                <button type="submit" className="btn btn-primary">
                  Submit Resource
                </button>
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={onBack}
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
