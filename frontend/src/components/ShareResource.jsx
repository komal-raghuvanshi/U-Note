import { useState, useEffect } from 'react'
import { apiFetch } from '../api'
import { useAcademicOptions } from '../hooks/useAcademicOptions'

const MAX_RESOURCE_FILE_SIZE = import.meta.env.PROD
  ? 4 * 1024 * 1024
  : 25 * 1024 * 1024
const MAX_RESOURCE_FILE_SIZE_MB = MAX_RESOURCE_FILE_SIZE / (1024 * 1024)

function ShareResource({ onBack, onNavigate, user, requestId }) {
  const [submitted, setSubmitted] = useState(false)
  const [file, setFile] = useState(null)
  const [error, setError] = useState('')
  const [uploading, setUploading] = useState(false)
  const [linkedRequest, setLinkedRequest] = useState(null)
  const [loadingRequest, setLoadingRequest] = useState(Boolean(requestId))

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    branch: '',
    semester: '',
    subject: '',
    unit: '',
    type: ''
  })

  const [unitOptions, setUnitOptions] = useState([])
  const [unitsLoading, setUnitsLoading] = useState(false)
  const {
    branches: branchOptions,
    semesters,
    subjects: subjectOptions,
    subjectsLoading,
    branchesLoading,
    semestersLoading,
  } = useAcademicOptions(formData.branch, formData.semester)
  const isYouTubeResource = formData.type.toLowerCase().includes('youtube')

  useEffect(() => {
    let ignore = false

    async function loadRequest() {
      if (!requestId) {
        setLinkedRequest(null)
        setLoadingRequest(false)
        return
      }
      if (!user?.token) {
        setLoadingRequest(false)
        setError('Log in to share a resource for this request.')
        return
      }

      setLoadingRequest(true)
      try {
        const response = await apiFetch(`/requests/${requestId}`, {}, user.token)
        const data = await response.json()
        if (!response.ok || !data.success) {
          throw new Error(data.message || 'Unable to load this resource request.')
        }
        if (!ignore) {
          const currentRequest = data.request
          setLinkedRequest(currentRequest)
          setFormData((previous) => ({
            ...previous,
            title: `Resource for ${currentRequest.subject}`,
            description: currentRequest.description,
            branch: currentRequest.branch,
            semester: String(currentRequest.semester_num),
            subject: currentRequest.subject,
            unit: currentRequest.unit ? String(currentRequest.unit) : 'all',
          }))
        }
      } catch (loadError) {
        if (!ignore) setError(loadError.message || 'Unable to load this resource request.')
      } finally {
        if (!ignore) setLoadingRequest(false)
      }
    }

    loadRequest()
    return () => { ignore = true }
  }, [requestId, user?.token])

  // Fetch units when subject changes
  useEffect(() => {
    let ignore = false

    async function fetchUnits() {
      if (!formData.subject) {
        setUnitOptions([])
        return
      }

      setUnitsLoading(true)
      const params = new URLSearchParams()
      params.append('subject', formData.subject)
      if (formData.branch) params.append('branch', formData.branch)
      if (formData.semester) params.append('semester', formData.semester)

      try {
        const res = await apiFetch(`/units?${params.toString()}`)
        if (!res.ok) throw new Error('failed')
        const data = await res.json()
        if (!ignore) {
          setUnitOptions(Array.isArray(data) ? data : [])
          setUnitsLoading(false)
        }
      } catch {
        if (!ignore) {
          setUnitOptions([])
          setUnitsLoading(false)
        }
      }
    }

    fetchUnits()
    return () => { ignore = true }
  }, [formData.subject, formData.branch, formData.semester])

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData((prev) => ({
      ...prev,
      [name]: value,
      ...(name === 'branch'
        ? { semester: '', subject: '', unit: '' }
        : name === 'semester'
          ? { subject: '', unit: '' }
        : name === 'subject'
          ? { unit: '' }
          : {})
    }))
  }

  const handleFileChange = (event) => {
    const selectedFile = event.target.files[0] || null
    if (selectedFile && selectedFile.size > MAX_RESOURCE_FILE_SIZE) {
      setFile(null)
      setError(`Choose a file no larger than ${MAX_RESOURCE_FILE_SIZE_MB} MB.`)
      event.target.value = ''
      return
    }

    setFile(selectedFile)
    setError('')
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    setError('')

    if (!user?.id || !user?.token) {
      setError('Please log in before sharing a study resource.')
      return
    }

    if (requestId && (!linkedRequest || linkedRequest.status !== 'Pending')) {
      setError('This request is not available for fulfillment.')
      return
    }

    const youtubeUrl = event.currentTarget.elements.youtube_url?.value.trim() || ''
    if (!file && !youtubeUrl) {
      setError('Add a valid YouTube URL or choose a file to upload.')
      return
    }

    const data = new FormData()
    if (file) data.append('file', file)
    data.append('title', formData.title)
    data.append('description', formData.description)
    data.append('branch', formData.branch)
    data.append('semester', formData.semester)
    data.append('subject', formData.subject)
    data.append('unit', formData.unit)
    data.append('type', formData.type)
    if (requestId) data.append('request_id', requestId)
    if (youtubeUrl) data.append('youtube_url', youtubeUrl)

    try {
      setUploading(true)

      const response = await apiFetch(
        '/resources/upload',
        {
          method: 'POST',
          body: data
        },
        user.token
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

          {!user && (
            <div className="prototype-badge-box auth-notice-box" style={{ backgroundColor: '#eff6ff', borderColor: '#bfdbfe', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem' }}>
              <div>
                <span className="prototype-badge-pill" style={{ backgroundColor: '#1d4ed8' }}>Login Required</span>
                <p className="prototype-badge-text" style={{ color: '#1e40af', marginTop: '0.35rem' }}>
                  You must be logged in to upload and share study resources.
                </p>
              </div>
              <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                <button
                  type="button"
                  className="btn btn-primary"
                  style={{ padding: '0.45rem 1rem', fontSize: '0.875rem' }}
                  onClick={() => onNavigate ? onNavigate('/login') : (window.location.href = '/login')}
                >
                  Log In
                </button>
                <button
                  type="button"
                  className="btn btn-outline"
                  style={{ padding: '0.45rem 1rem', fontSize: '0.875rem' }}
                  onClick={() => onNavigate ? onNavigate('/signup') : (window.location.href = '/signup')}
                >
                  Sign Up
                </button>
              </div>
            </div>
          )}

          {requestId && (
            <div className="prototype-badge-box" style={{ backgroundColor: '#eff6ff', borderColor: '#bfdbfe' }}>
              <span className="prototype-badge-pill" style={{ backgroundColor: '#1d4ed8' }}>
                {loadingRequest ? 'Loading Request' : linkedRequest?.status || 'Request'}
              </span>
              <p className="prototype-badge-text" style={{ color: '#1e40af' }}>
                {loadingRequest
                  ? 'Loading the request details to pre-fill the sharing form.'
                  : linkedRequest
                    ? `Sharing a resource for ${linkedRequest.subject} (${linkedRequest.branch}, Semester ${linkedRequest.semester_num}).`
                    : 'Request details could not be loaded.'}
              </p>
            </div>
          )}

          {submitted ? (
            <div className="submission-success-card">
              <h3>File Uploaded Successfully!</h3>

              <p>
                <strong>{formData.title}</strong> ({formData.type}) for{' '}
                {formData.branch} Semester {formData.semester}.
              </p>

              <p className="success-note">
                {requestId
                  ? 'Your resource has been saved and linked to the request, which is now marked Fulfilled.'
                  : file
                    ? 'Your file and resource details have been successfully uploaded and saved to the database.'
                    : 'Your YouTube resource details have been saved to the database.'}
                {' '}
                You can now view this resource on the Resources page or under My Shared Resources in your profile.
              </p>

              <div className="success-actions">
                <button
                  type="button"
                  className="btn btn-primary"
                  onClick={onBack}
                >
                  {requestId ? 'Return to Requests' : 'Return to Home'}
                </button>

                {!requestId && (
                  <button
                    type="button"
                    className="btn btn-secondary"
                    onClick={() => {
                      setSubmitted(false)
                      setFile(null)
                      setError('')
                      setFormData({
                        title: '',
                        description: '',
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
                )}
              </div>
            </div>
          ) : (
            <form
              className="share-resource-form"
              onSubmit={handleSubmit}
            >
              <div className="form-group">
                <label htmlFor="title">Resource Title *</label>
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
                  <label htmlFor="branch">Branch *</label>
                  <select
                    id="branch"
                    name="branch"
                    className="form-control"
                    value={formData.branch}
                    onChange={handleChange}
                    required
                    disabled={Boolean(requestId)}
                  >
                    <option value="" disabled>
                      {branchesLoading ? 'Loading branches...' : 'Select branch'}
                    </option>
                    {branchOptions.map((branch) => (
                      <option key={branch.id} value={branch.name}>{branch.name}</option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label htmlFor="semester">Semester *</label>
                  <select
                    id="semester"
                    name="semester"
                    className="form-control"
                    value={formData.semester}
                    onChange={handleChange}
                    required
                    disabled={Boolean(requestId) || !formData.branch || branchesLoading || semestersLoading}
                  >
                    <option value="" disabled>
                      {!formData.branch
                        ? 'Select branch first'
                        : semestersLoading
                          ? 'Loading semesters...'
                          : 'Select semester'}
                    </option>
                    {semesters.map((sem) => (
                      <option key={sem.id} value={sem.number}>
                        {sem.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="subject">Subject Name *</label>
                  <select
                    id="subject"
                    name="subject"
                    className="form-control"
                    value={formData.subject}
                    onChange={handleChange}
                    required
                    disabled={Boolean(requestId) || !formData.branch || !formData.semester || subjectsLoading || subjectOptions.length === 0}
                  >
                    <option value="">
                      {subjectsLoading
                        ? 'Loading subjects...'
                        : subjectOptions.length === 0
                          ? (formData.branch && formData.semester ? 'No subjects found' : 'Select branch & semester first')
                          : 'Select subject'}
                    </option>
                    {subjectOptions.map((s) => (
                      <option key={s.id} value={s.name}>{s.name}</option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label htmlFor="unit">Unit *</label>
                  <select
                    id="unit"
                    name="unit"
                    className="form-control"
                    value={formData.unit}
                    onChange={handleChange}
                    required
                    disabled={Boolean(requestId) || unitsLoading || !formData.subject}
                  >
                    <option value="" disabled>
                      {!formData.subject ? 'Select subject first' : unitsLoading ? 'Loading units...' : 'Select unit'}
                    </option>
                    <option value="all">All Units (Complete Subject Material)</option>
                    {unitOptions.length > 0 ? (
                      unitOptions.map((u) => (
                        <option key={u.id || u.unit_number} value={u.unit_number}>
                          Unit {u.unit_number}
                        </option>
                      ))
                    ) : (
                      null
                    )}
                  </select>
                </div>
              </div>

              <div className="form-group">
                <label htmlFor="type">Resource Type *</label>
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
                  <option value="Previous Year Question Papers">Previous Year Question Papers</option>
                  <option value="Important Questions">Important Questions</option>
                  <option value="YouTube Resources">YouTube Resources</option>
                  <option value="Teacher Resources">Teacher Resources</option>
                </select>
              </div>

              <div className="form-group">
                <label htmlFor="description">Description (Optional)</label>
                <textarea
                  id="description"
                  name="description"
                  className="form-control"
                  rows="3"
                  placeholder="Add details about topics covered, author, or exam tips..."
                  value={formData.description}
                  onChange={handleChange}
                ></textarea>
              </div>

              {isYouTubeResource && (
                <div className="form-group">
                  <label htmlFor="youtube_url">YouTube URL *</label>
                  <input
                    type="url"
                    id="youtube_url"
                    name="youtube_url"
                    className="form-control"
                    placeholder="https://www.youtube.com/watch?v=..."
                    pattern="https?://.+"
                    required={!file}
                  />
                </div>
              )}

              <div className="form-group">
                <label htmlFor="file">
                  {isYouTubeResource ? 'Or select a file (PDF, PNG, JPG, JPEG)' : 'Select File (PDF, PNG, JPG, JPEG) *'}
                </label>
                <input
                  type="file"
                  id="file"
                  name="file"
                  className="form-control file-input"
                  accept=".pdf,.png,.jpg,.jpeg"
                  onChange={handleFileChange}
                  required={!isYouTubeResource}
                />
                <p className="success-note">
                  Maximum file size: {MAX_RESOURCE_FILE_SIZE_MB} MB.
                  {import.meta.env.PROD && ' Hosted uploads use temporary storage and may not persist.'}
                </p>
              </div>

              {error && (
                <p className="error-message" role="alert" style={{ color: '#dc2626', fontWeight: 500, margin: '0.5rem 0' }}>
                  {error}
                </p>
              )}

              <div className="form-button-row">
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={!user || uploading || loadingRequest || (requestId && linkedRequest?.status !== 'Pending')}
                  title={!user ? 'Please log in to submit a resource' : undefined}
                >
                  {uploading ? 'Uploading...' : !user ? 'Log In to Submit' : 'Submit Resource'}
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
