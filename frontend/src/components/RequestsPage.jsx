import { useState, useEffect, useCallback } from 'react'
import { apiFetch } from '../api'

function RequestsPage({ user, onNavigate }) {
  const [activeTab, setActiveTab] = useState('browse') // 'browse' | 'create' | 'my'
  const [requests, setRequests] = useState([])
  const [myRequests, setMyRequests] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [successMsg, setSuccessMsg] = useState('')

  // Filter state for browsing
  const [statusFilter, setStatusFilter] = useState('all')
  const [branchFilter, setBranchFilter] = useState('')
  const [searchFilter, setSearchFilter] = useState('')

  // New Request Form state
  const [formData, setFormData] = useState({
    branch: user?.branch || 'AIML',
    semester: user?.semester || '4',
    subject: '',
    unit: 'all',
    description: ''
  })
  const [subjectOptions, setSubjectOptions] = useState([])
  const [subjectsLoading, setSubjectsLoading] = useState(false)
  const [unitOptions, setUnitOptions] = useState([])
  const [branchOptions, setBranchOptions] = useState([])
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    let ignore = false
    apiFetch('/branches')
      .then(async (response) => {
        const data = await response.json()
        if (response.ok && !ignore) {
          setBranchOptions(Array.isArray(data.branches) ? data.branches : [])
        }
      })
      .catch(() => {
        if (!ignore) setBranchOptions([])
      })
    return () => { ignore = true }
  }, [])

  // Fetch community requests
  const fetchRequests = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const params = new URLSearchParams()
      if (branchFilter) params.append('branch', branchFilter)
      if (statusFilter && statusFilter !== 'all') params.append('status', statusFilter)

      const res = await apiFetch(`/requests?${params.toString()}`)
      const data = await res.json()
      if (res.ok && data.success) {
        setRequests(data.requests || [])
      } else {
        setError(data.message || 'Unable to load study requests.')
      }
    } catch {
      setError('Cannot connect to the server. Please verify Flask backend is running.')
    } finally {
      setLoading(false)
    }
  }, [branchFilter, statusFilter])

  // Fetch user's own requests
  const fetchMyRequests = useCallback(async () => {
    if (!user?.token) return
    try {
      const res = await apiFetch('/requests/my', {}, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        setMyRequests(data.requests || [])
      } else {
        setError(data.message || 'Unable to load your requests.')
      }
    } catch {
      setError('Unable to connect while loading your requests.')
    }
  }, [user])

  useEffect(() => {
    fetchRequests()
  }, [fetchRequests])

  useEffect(() => {
    if (activeTab === 'my') {
      fetchMyRequests()
    }
  }, [activeTab, fetchMyRequests])

  // Fetch dynamic subjects when form branch/semester change
  useEffect(() => {
    let ignore = false
    async function loadSubjects() {
      if (!formData.branch || !formData.semester) {
        setSubjectOptions([])
        return
      }
      setSubjectsLoading(true)
      try {
        const params = new URLSearchParams({
          branch: formData.branch,
          semester: formData.semester
        })
        const res = await apiFetch(`/subjects?${params.toString()}`)
        const data = await res.json()
        if (!ignore) {
          const list = Array.isArray(data) ? data : []
          setSubjectOptions(list)
          if (list.length > 0 && !formData.subject) {
            setFormData((prev) => ({ ...prev, subject: list[0].name }))
          }
        }
      } catch {
        if (!ignore) setSubjectOptions([])
      } finally {
        if (!ignore) setSubjectsLoading(false)
      }
    }

    loadSubjects()
    return () => { ignore = true }
  }, [formData.branch, formData.semester, formData.subject])

  // Fetch units when subject changes in form
  useEffect(() => {
    let ignore = false
    async function loadUnits() {
      if (!formData.subject) {
        setUnitOptions([])
        return
      }
      try {
        const params = new URLSearchParams({
          subject: formData.subject,
          branch: formData.branch,
          semester: formData.semester
        })
        const res = await apiFetch(`/units?${params.toString()}`)
        const data = await res.json()
        if (!ignore) {
          setUnitOptions(Array.isArray(data) ? data : [])
        }
      } catch {
        if (!ignore) setUnitOptions([])
      }
    }

    loadUnits()
    return () => { ignore = true }
  }, [formData.subject, formData.branch, formData.semester])

  const handleFormChange = (e) => {
    const { name, value } = e.target
    setFormData((prev) => ({
      ...prev,
      [name]: value,
      ...(name === 'branch' || name === 'semester'
        ? { subject: '', unit: 'all' }
        : name === 'subject'
          ? { unit: 'all' }
          : {})
    }))
  }

  const handleSubmitRequest = async (e) => {
    e.preventDefault()
    setError('')
    setSuccessMsg('')

    if (!user?.id) {
      setError('Please log in to submit a resource request.')
      return
    }

    if (!formData.description.trim()) {
      setError('Please describe what study material or notes you need.')
      return
    }

    setSubmitting(true)
    try {
      const res = await apiFetch('/requests', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          branch: formData.branch,
          semester: formData.semester,
          subject: formData.subject,
          unit: formData.unit,
          description: formData.description.trim()
        }, user.token)
      })

      const data = await res.json()
      if (res.ok && data.success) {
        setSuccessMsg('Your request has been submitted to the community!')
        setFormData((prev) => ({ ...prev, description: '' }))
        fetchRequests()
        setTimeout(() => {
          setActiveTab('browse')
          setSuccessMsg('')
        }, 1500)
      } else {
        setError(data.message || 'Failed to submit request.')
      }
    } catch {
      setError('Failed to connect to backend server.')
    } finally {
      setSubmitting(false)
    }
  }

  const handleUpdateStatus = async (requestId, newStatus) => {
    try {
      const res = await apiFetch(`/requests/${requestId}/status`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: newStatus
        })
      }, user?.token)
      const data = await res.json()
      if (res.ok && data.success) {
        fetchRequests()
        if (activeTab === 'my') fetchMyRequests()
      } else {
        setError(data.message || 'Unable to update request status.')
      }
    } catch {
      setError('Unable to connect while updating request status.')
    }
  }

  // Filter client side by search term
  const displayedRequests = (activeTab === 'my' ? myRequests : requests).filter((req) => {
    if (!searchFilter) return true
    const term = searchFilter.toLowerCase()
    return (
      (req.subject && req.subject.toLowerCase().includes(term)) ||
      (req.description && req.description.toLowerCase().includes(term)) ||
      (req.branch && req.branch.toLowerCase().includes(term)) ||
      (req.user_name && req.user_name.toLowerCase().includes(term))
    )
  })

  return (
    <div className="requests-page-container">
      <div className="section-container requests-content">
        <header className="requests-page-header">
          <div className="page-header-text">
            <h1 className="page-title">Study Resource Requests</h1>
            <p className="page-subtitle">
              Can&apos;t find notes, question papers, or solutions for a unit? Request them from peers and faculty.
            </p>
          </div>

          {/* Navigation Tabs */}
          <div className="requests-tab-row">
            <button
              type="button"
              className={`btn requests-tab-btn ${activeTab === 'browse' ? 'active' : 'btn-secondary'}`}
              onClick={() => setActiveTab('browse')}
              aria-pressed={activeTab === 'browse'}
            >
              Browse All Requests ({requests.length})
            </button>
            <button
              type="button"
              className={`btn requests-tab-btn ${activeTab === 'create' ? 'active' : 'btn-secondary'}`}
              onClick={() => setActiveTab('create')}
              aria-pressed={activeTab === 'create'}
            >
              + Request Notes / Material
            </button>
            {user && (
              <button
                type="button"
                className={`btn requests-tab-btn ${activeTab === 'my' ? 'active' : 'btn-secondary'}`}
                onClick={() => setActiveTab('my')}
                aria-pressed={activeTab === 'my'}
              >
                My Requests ({myRequests.length})
              </button>
            )}
          </div>
        </header>

      <div className="requests-page-body">
        {error && (
          <div className="auth-error-banner" style={{ marginBottom: '1.5rem' }}>
            {error}
          </div>
        )}

        {successMsg && (
          <div className="prototype-badge-box" style={{ marginBottom: '1.5rem' }}>
            <span className="prototype-badge-pill" style={{ backgroundColor: '#15803d' }}>Success</span>
            <p className="prototype-badge-text">{successMsg}</p>
          </div>
        )}

        {/* Tab 1: Create Request */}
        {activeTab === 'create' && (
          <div className="share-form-wrapper request-form-wrapper">
            <h2 className="share-form-title" style={{ fontSize: '1.5rem', marginBottom: '0.5rem' }}>
              Submit a Resource Request
            </h2>
            <p className="share-form-subtitle" style={{ marginBottom: '1.5rem' }}>
              Fill in the academic details so teachers or students can share the exact material you need.
            </p>

            {!user ? (
              <div className="prototype-badge-box" style={{ backgroundColor: '#eff6ff', borderColor: '#bfdbfe' }}>
                <span className="prototype-badge-pill" style={{ backgroundColor: '#1d4ed8' }}>Login Needed</span>
                <p className="prototype-badge-text" style={{ color: '#1e40af' }}>
                  Please <button type="button" onClick={() => onNavigate('/login')} style={{ background: 'none', border: 'none', color: '#1d4ed8', fontWeight: 700, cursor: 'pointer', textDecoration: 'underline' }}>log in</button> or <button type="button" onClick={() => onNavigate('/signup')} style={{ background: 'none', border: 'none', color: '#1d4ed8', fontWeight: 700, cursor: 'pointer', textDecoration: 'underline' }}>sign up</button> to request study material.
                </p>
              </div>
            ) : (
              <form onSubmit={handleSubmitRequest} className="share-resource-form">
                <div className="form-row">
                  <div className="form-group">
                    <label htmlFor="req-branch">Branch *</label>
                    <select
                      id="req-branch"
                      name="branch"
                      className="form-control"
                      value={formData.branch}
                      onChange={handleFormChange}
                      required
                    >
                      {branchOptions.map((branch) => (
                        <option key={branch.id} value={branch.name}>{branch.name}</option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label htmlFor="req-sem">Semester *</label>
                    <select
                      id="req-sem"
                      name="semester"
                      className="form-control"
                      value={formData.semester}
                      onChange={handleFormChange}
                      required
                    >
                      {[1, 2, 3, 4, 5, 6, 7, 8].map((s) => (
                        <option key={s} value={s}>Semester {s}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label htmlFor="req-subject">Subject *</label>
                    <select
                      id="req-subject"
                      name="subject"
                      className="form-control"
                      value={formData.subject}
                      onChange={handleFormChange}
                      required
                      disabled={subjectsLoading}
                    >
                      {subjectsLoading ? (
                        <option>Loading subjects...</option>
                      ) : subjectOptions.length === 0 ? (
                        <option value="">No subjects found for selection</option>
                      ) : (
                        subjectOptions.map((subj) => (
                          <option key={subj.id || subj.code} value={subj.name}>
                            {subj.code ? `${subj.code} - ` : ''}{subj.name}
                          </option>
                        ))
                      )}
                    </select>
                  </div>

                  <div className="form-group">
                    <label htmlFor="req-unit">Unit</label>
                    <select
                      id="req-unit"
                      name="unit"
                      className="form-control"
                      value={formData.unit}
                      onChange={handleFormChange}
                    >
                      <option value="all">All Units / Whole Syllabus</option>
                      {unitOptions.map((u) => (
                        <option key={u.unit_id || u.unit_number} value={u.unit_number}>
                          Unit {u.unit_number}: {u.unit_name}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="form-group">
                  <label htmlFor="req-desc">What study material are you looking for? *</label>
                  <textarea
                    id="req-desc"
                    name="description"
                    className="form-control"
                    rows={4}
                    placeholder="e.g. Need handwritten notes with solved numericals for Unit 3 (Dynamic Programming), or 2024 previous year question solutions."
                    value={formData.description}
                    onChange={handleFormChange}
                    required
                  />
                </div>

                <div className="form-button-row">
                  <button type="submit" className="btn btn-primary" disabled={submitting}>
                    {submitting ? 'Submitting...' : 'Post Request'}
                  </button>
                  <button
                    type="button"
                    className="btn btn-secondary"
                    onClick={() => setActiveTab('browse')}
                  >
                    Cancel
                  </button>
                </div>
              </form>
            )}
          </div>
        )}

        {/* Tab 2 & 3: Browse All or My Requests */}
        {activeTab !== 'create' && (
          <>
            {/* Filter controls */}
            <div className="filters-card requests-filter-card">
              <div className="filters-grid requests-filter-grid">
                <div className="filter-item">
                  <label htmlFor="filter-search">Search Requests</label>
                  <input
                    type="text"
                    id="filter-search"
                    className="form-control"
                    placeholder="Filter by subject or keyword..."
                    value={searchFilter}
                    onChange={(e) => setSearchFilter(e.target.value)}
                  />
                </div>

                <div className="filter-item">
                  <label htmlFor="filter-branch">Branch</label>
                  <select
                    id="filter-branch"
                    className="form-control"
                    value={branchFilter}
                    onChange={(e) => setBranchFilter(e.target.value)}
                  >
                    <option value="">All Branches</option>
                    {branchOptions.map((branch) => (
                      <option key={branch.id} value={branch.name}>{branch.name}</option>
                    ))}
                  </select>
                </div>

                <div className="filter-item">
                  <label htmlFor="filter-status">Status</label>
                  <select
                    id="filter-status"
                    className="form-control"
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                  >
                    <option value="all">All Statuses</option>
                    <option value="Pending">Pending (Unfulfilled)</option>
                    <option value="Fulfilled">Fulfilled</option>
                  </select>
                </div>
              </div>
            </div>

            {/* List */}
            {loading ? (
              <div className="resources-loading-box">
                <p>Loading study requests...</p>
              </div>
            ) : displayedRequests.length === 0 ? (
              <div className="no-results-box">
                <h3>No requests found</h3>
                <p>
                  {activeTab === 'my'
                    ? "You haven't submitted any study material requests yet."
                    : 'No requests matched your filter. You can submit a request if you need materials.'}
                </p>
                <button
                  type="button"
                  className="btn btn-primary"
                  onClick={() => setActiveTab('create')}
                >
                  + Request Notes
                </button>
              </div>
            ) : (
              <div className="requests-grid">
                {displayedRequests.map((req) => {
                  const isFulfilled = req.status === 'Fulfilled'
                  const canManage = user?.role === 'teacher' || (user?.id && user.id === req.user_id)
                  return (
                    <div key={req.id} className="request-card">
                      <div className="request-card-header">
                        <div className="request-tags">
                          <span className="request-branch-badge">
                            {req.branch} · {req.semester}
                          </span>
                          <span className={`request-status-badge ${isFulfilled ? 'status-fulfilled' : 'status-pending'}`}>
                            {req.status}
                          </span>
                        </div>
                        <span className="request-date">
                          {req.created_at ? new Date(req.created_at).toLocaleDateString() : ''}
                        </span>
                      </div>

                      <h3 className="request-subject-title">
                        {req.subject_code ? `${req.subject_code} - ` : ''}{req.subject}
                      </h3>

                      <p className="request-unit-tag">
                        Scope: <strong>{req.unit ? `Unit ${req.unit}${req.unit_name ? `: ${req.unit_name}` : ''}` : 'All Units'}</strong>
                      </p>

                      <div className="request-description-box">
                        <p>{req.description}</p>
                      </div>

                      <div className="request-footer">
                        <div className="request-user-info">
                          <span className="request-avatar-circle">
                            {(req.user_name || 'U').charAt(0).toUpperCase()}
                          </span>
                          <div>
                            <p className="request-user-name">{req.user_name || 'Student'}</p>
                            <span className="request-user-role">{req.user_role === 'teacher' ? 'Faculty Member' : 'Student'}</span>
                          </div>
                        </div>

                        <div className="request-actions">
                          {!isFulfilled && (
                            <button
                              type="button"
                              className="btn btn-secondary btn-sm"
                              onClick={() => onNavigate('/share-resource')}
                              title="Upload and share the notes requested here"
                            >
                              Share Notes &rarr;
                            </button>
                          )}

                          {canManage && !isFulfilled && (
                            <button
                              type="button"
                              className="btn btn-outline btn-sm"
                              onClick={() => handleUpdateStatus(req.id, 'Fulfilled')}
                            >
                              Mark Fulfilled ✓
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </>
        )}
      </div>
      </div>
    </div>
  )
}

export default RequestsPage
