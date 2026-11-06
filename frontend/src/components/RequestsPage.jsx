import { useState, useEffect, useCallback } from 'react'
import { apiFetch, apiUrl } from '../api'
import { useAcademicOptions } from '../hooks/useAcademicOptions'

function RequestsPage({ user, onNavigate }) {
  const [activeTab, setActiveTab] = useState('browse') // 'browse' | 'create' | 'my'
  const [requests, setRequests] = useState([])
  const [myRequests, setMyRequests] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [successMsg, setSuccessMsg] = useState('')
  const [editingRequestId, setEditingRequestId] = useState(null)

  // Filter state for browsing
  const [statusFilter, setStatusFilter] = useState('all')
  const [branchFilter, setBranchFilter] = useState('')
  const [searchFilter, setSearchFilter] = useState('')

  // New Request Form state
  const [formData, setFormData] = useState({
    branch: user?.branch || '',
    semester: user?.semester || '',
    subject: '',
    unit: 'all',
    title: '',
    description: ''
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
  const [submitting, setSubmitting] = useState(false)

  // Fetch community requests
  const fetchRequests = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const params = new URLSearchParams()
      if (branchFilter) params.append('branch', branchFilter)
      if (statusFilter && statusFilter !== 'all') params.append('status', statusFilter)

      const res = await apiFetch(`/requests?${params.toString()}`, {}, user.token)
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
  }, [branchFilter, statusFilter, user])

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

  // Initial fetch for browse requests
  useEffect(() => {
    fetchRequests()
  }, [fetchRequests])

  // Initial fetch for my requests when user is logged in
  useEffect(() => {
    if (user?.token) {
      fetchMyRequests()
    } else {
      setMyRequests([])
    }
  }, [user, fetchMyRequests])

  // Fetch units when form subject, branch, or semester changes
  useEffect(() => {
    let ignore = false
    async function loadUnits() {
      if (!formData.subject) {
        setUnitOptions([])
        setUnitsLoading(false)
        return
      }
      setUnitsLoading(true)
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
      } finally {
        if (!ignore) setUnitsLoading(false)
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
      ...(name === 'branch'
        ? { semester: '', subject: '', unit: 'all' }
        : name === 'semester'
          ? { subject: '', unit: 'all' }
        : name === 'subject'
          ? { unit: 'all' }
          : {})
    }))
  }

  const handleTabChange = (tab) => {
    setEditingRequestId(null)
    setActiveTab(tab)
    setError('')
    setSuccessMsg('')
    if (tab === 'my' && user?.token) {
      fetchMyRequests()
    } else if (tab === 'browse') {
      fetchRequests()
    }
  }

  const handleSubmitRequest = async (e) => {
    e.preventDefault()
    setError('')
    setSuccessMsg('')

    if (!user?.id || !user?.token) {
      setError('Please log in to submit a resource request.')
      return
    }

    if (!formData.branch || !formData.semester || !formData.subject) {
      setError('Please select a branch, semester, and subject.')
      return
    }

    if (!formData.description.trim()) {
      setError('Please describe what study material or notes you need.')
      return
    }
    if (!formData.title.trim()) {
      setError('Please enter a title for your request.')
      return
    }

    setSubmitting(true)
    try {
      const isEditing = Boolean(editingRequestId)
      const res = await apiFetch(
        isEditing ? `/requests/${editingRequestId}` : '/requests',
        {
          method: isEditing ? 'PATCH' : 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            title: formData.title.trim(),
            branch: formData.branch,
            semester: formData.semester,
            subject: formData.subject,
            unit: formData.unit,
            description: formData.description.trim()
          })
        },
        user.token
      )

      const contentType = res.headers.get('content-type') || ''
      if (!contentType.includes('application/json')) {
        setError(
          `Unable to ${isEditing ? 'save changes' : 'submit the request'}: ` +
          `the server returned an unexpected response (HTTP ${res.status}).`
        )
        return
      }

      const data = await res.json()
      if (res.ok && data.success) {
        setSuccessMsg(isEditing
          ? 'Your request has been updated.'
          : 'Your request has been submitted to the community!')
        setEditingRequestId(null)
        setFormData((prev) => ({ ...prev, title: '', description: '' }))
        fetchRequests()
        if (user?.token) {
          fetchMyRequests()
        }
        if (isEditing) {
          setActiveTab('my')
        } else {
          setTimeout(() => {
            setActiveTab('browse')
            setSuccessMsg('')
          }, 1500)
        }
      } else {
        setError(data.message || 'Failed to submit request.')
      }
    } catch {
      setError('Failed to connect to backend server.')
    } finally {
      setSubmitting(false)
    }
  }

  const handleEditRequest = (req) => {
    setError('')
    setSuccessMsg('')
    setEditingRequestId(req.id)
    setFormData({
      branch: req.branch || '',
      semester: String(req.semester_num || req.semester || '').replace('Semester ', ''),
      subject: req.subject || '',
      unit: req.unit ? String(req.unit) : 'all',
      title: req.title || req.subject || '',
      description: req.description || ''
    })
    setActiveTab('create')
  }

  const handleDeleteRequest = async (requestId) => {
    if (!window.confirm('Permanently delete this request? Any linked resource will remain available.')) {
      return
    }
    setError('')
    setSuccessMsg('')
    try {
      const res = await apiFetch(
        `/requests/${requestId}`,
        { method: 'DELETE' },
        user.token
      )
      const data = await res.json()
      if (!res.ok || !data.success) {
        setError(data.message || 'Unable to delete this request.')
        return
      }
      setSuccessMsg(data.message || 'Request deleted successfully.')
      fetchRequests()
      fetchMyRequests()
    } catch {
      setError('Unable to connect while deleting this request.')
    }
  }

  const handleUpdateStatus = async (requestId, newStatus) => {
    if (!user?.token) {
      setError('Authentication required to update request status.')
      return
    }
    try {
      const res = await apiFetch(
        `/requests/${requestId}/status`,
        {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            status: newStatus
          })
        },
        user.token
      )
      const data = await res.json()
      if (res.ok && data.success) {
        setSuccessMsg(data.message || 'Request status updated.')
        setError('')
        fetchRequests()
        if (user?.token) fetchMyRequests()
      } else {
        setError(data.message || 'Unable to update request status.')
      }
    } catch {
      setError('Unable to connect while updating request status.')
    }
  }

  const handleResetFilters = () => {
    setSearchFilter('')
    setBranchFilter('')
    setStatusFilter('all')
  }

  const hasActiveFilters = Boolean(
    searchFilter || branchFilter || (statusFilter && statusFilter !== 'all')
  )

  // Filter client side for tab-specific items and search
  const displayedRequests = (activeTab === 'my' ? myRequests : requests).filter((req) => {
    if (activeTab === 'my') {
      if (branchFilter && req.branch && req.branch.toLowerCase() !== branchFilter.toLowerCase()) {
        return false
      }
      if (statusFilter && statusFilter !== 'all' && req.status && req.status.toLowerCase() !== statusFilter.toLowerCase()) {
        return false
      }
    }
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
              onClick={() => handleTabChange('browse')}
              aria-pressed={activeTab === 'browse'}
            >
              Browse All Requests ({requests.length})
            </button>
            <button
              type="button"
              className={`btn requests-tab-btn ${activeTab === 'create' ? 'active' : 'btn-secondary'}`}
              onClick={() => handleTabChange('create')}
              aria-pressed={activeTab === 'create'}
            >
              + Request Notes / Material
            </button>
            {user?.token && (
              <button
                type="button"
                className={`btn requests-tab-btn ${activeTab === 'my' ? 'active' : 'btn-secondary'}`}
                onClick={() => handleTabChange('my')}
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
                {editingRequestId ? 'Edit Resource Request' : 'Submit a Resource Request'}
              </h2>
              <p className="share-form-subtitle" style={{ marginBottom: '1.5rem' }}>
                Fill in the academic details so teachers or students can share the exact material you need.
              </p>

              {!user ? (
                <div className="prototype-badge-box" style={{ backgroundColor: '#eff6ff', borderColor: '#bfdbfe' }}>
                  <span className="prototype-badge-pill" style={{ backgroundColor: '#1d4ed8' }}>Login Needed</span>
                  <p className="prototype-badge-text" style={{ color: '#1e40af' }}>
                    Please{' '}
                    <button
                      type="button"
                      onClick={() => onNavigate('/login')}
                      style={{ background: 'none', border: 'none', color: '#1d4ed8', fontWeight: 700, cursor: 'pointer', textDecoration: 'underline' }}
                    >
                      log in
                    </button>{' '}
                    or{' '}
                    <button
                      type="button"
                      onClick={() => onNavigate('/signup')}
                      style={{ background: 'none', border: 'none', color: '#1d4ed8', fontWeight: 700, cursor: 'pointer', textDecoration: 'underline' }}
                    >
                      sign up
                    </button>{' '}
                    to request study material.
                  </p>
                </div>
              ) : (
                <form onSubmit={handleSubmitRequest} className="share-resource-form">
                  <div className="form-group">
                    <label htmlFor="req-title">Request title *</label>
                    <input
                      id="req-title"
                      name="title"
                      type="text"
                      className="form-control"
                      maxLength={200}
                      placeholder="e.g. Machine Learning Unit 3 notes"
                      value={formData.title}
                      onChange={handleFormChange}
                      required
                    />
                  </div>

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
                        <option value="" disabled>
                          {branchesLoading ? 'Loading branches...' : 'Select branch'}
                        </option>
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
                        disabled={!formData.branch || branchesLoading || semestersLoading}
                      >
                        <option value="" disabled>
                          {!formData.branch
                            ? 'Select branch first'
                            : semestersLoading
                              ? 'Loading semesters...'
                              : 'Select semester'}
                        </option>
                        {semesters.map((sem) => (
                          <option key={sem.id} value={sem.number}>{sem.name}</option>
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
                        disabled={!formData.branch || !formData.semester || subjectsLoading || subjectOptions.length === 0}
                      >
                        <option value="">
                          {subjectsLoading
                            ? 'Loading subjects...'
                            : subjectOptions.length === 0
                              ? (formData.branch && formData.semester ? 'No subjects found' : 'Select branch & semester first')
                              : 'Select Subject'}
                        </option>
                        {subjectOptions.map((subj) => (
                          <option key={subj.id || subj.code} value={subj.name}>
                            {subj.name}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="form-group">
                      <label htmlFor="req-unit">Unit Scope</label>
                      <select
                        id="req-unit"
                        name="unit"
                        className="form-control"
                        value={formData.unit}
                        onChange={handleFormChange}
                        disabled={unitsLoading || !formData.subject}
                      >
                        <option value="all">
                          {unitsLoading ? 'Loading units...' : 'All Units (Complete Subject Material)'}
                        </option>
                        {unitOptions.map((u) => (
                          <option key={u.id || u.unit_id || u.unit_number} value={u.unit_number}>
                            Unit {u.unit_number}
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
                      {submitting
                        ? (editingRequestId ? 'Saving...' : 'Submitting...')
                        : (editingRequestId ? 'Save Changes' : 'Post Request')}
                    </button>
                    <button
                      type="button"
                      className="btn btn-secondary"
                      onClick={() => handleTabChange(editingRequestId ? 'my' : 'browse')}
                      disabled={submitting}
                    >
                      {editingRequestId ? 'Discard Changes' : 'Back to Requests'}
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
                      <option value="Rejected">Rejected</option>
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
                    {hasActiveFilters
                      ? 'No study requests matched your selected filters.'
                      : activeTab === 'my'
                        ? "You haven't submitted any study material requests yet."
                        : 'No requests available yet. You can submit a request if you need materials.'}
                  </p>
                  <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'center', marginTop: '1rem', flexWrap: 'wrap' }}>
                    {hasActiveFilters && (
                      <button
                        type="button"
                        className="btn btn-secondary"
                        onClick={handleResetFilters}
                      >
                        Reset Filters
                      </button>
                    )}
                    <button
                      type="button"
                      className="btn btn-primary"
                      onClick={() => handleTabChange('create')}
                    >
                      + Request Notes
                    </button>
                  </div>
                </div>
              ) : (
                <div className="requests-grid">
                  {displayedRequests.map((req) => {
                    const isFulfilled = req.status === 'Fulfilled'
                    const isRejected = req.status === 'Rejected'
                    const isPending = req.status === 'Pending'
                    const isOwner = Boolean(user?.id && String(user.id) === String(req.user_id))

                    const statusClass =
                      isFulfilled
                        ? 'status-fulfilled'
                        : isRejected
                          ? 'status-rejected'
                          : 'status-pending'

                    return (
                      <div key={req.id} className="request-card">
                        <div className="request-card-header">
                          <div className="request-tags">
                            <span className="request-branch-badge">
                              {req.branch} · {req.semester}
                            </span>
                            <span className={`request-status-badge ${statusClass}`}>
                              {req.status}
                            </span>
                          </div>
                          <span className="request-date">
                            {req.created_at ? new Date(req.created_at).toLocaleDateString() : ''}
                          </span>
                        </div>

                        <h3 className="request-subject-title">{req.title || req.subject}</h3>
                        {req.subject_code && (
                          <p className="request-subject-line">Subject code: {req.subject_code}</p>
                        )}

                        <p className="request-unit-tag">
                          Scope: <strong>{req.unit ? `Unit ${req.unit}${req.unit_name ? `: ${req.unit_name}` : ''}` : 'All Units'}</strong>
                        </p>

                        <div className="request-description-box">
                          <p>{req.description}</p>
                        </div>

                        {isFulfilled && (
                          <div className="request-description-box">
                            <p>
                              Shared by <strong>{req.fulfilled_by_name || 'Community member'}</strong>
                            </p>
                            {req.fulfilled_resource_title && req.fulfilled_resource_url && (
                              <a
                                href={req.fulfilled_resource_url.startsWith('http')
                                  ? req.fulfilled_resource_url
                                  : apiUrl(req.fulfilled_resource_url)}
                                target="_blank"
                                rel="noreferrer"
                              >
                                View shared resource: {req.fulfilled_resource_title}
                              </a>
                            )}
                          </div>
                        )}

                        <div className="request-footer">
                          <div className="request-user-info">
                            <span className="request-avatar-circle">
                              {(req.user_name || 'Community member').charAt(0).toUpperCase()}
                            </span>
                            <div>
                              <p className="request-user-name">{req.user_name || 'Community member'}</p>
                              {req.user_role && (
                                <span className="request-user-role">
                                  {req.user_role === 'teacher' ? 'Faculty Member' : 'Student'}
                                </span>
                              )}
                            </div>
                          </div>

                          <div className="request-actions">
                            {isPending && user?.token && (
                              <button
                                type="button"
                                className="btn btn-secondary btn-sm"
                                onClick={() => onNavigate(`/share-resource?request_id=${encodeURIComponent(req.id)}`)}
                                title="Upload and share the notes requested here"
                              >
                                Share Resource &rarr;
                              </button>
                            )}

                            {isOwner && isPending && (
                              <button
                                type="button"
                                className="btn btn-outline btn-sm"
                                onClick={() => handleEditRequest(req)}
                                title="Edit your pending request"
                              >
                                Edit
                              </button>
                            )}

                            {isOwner && isRejected && (
                              <button
                                type="button"
                                className="btn btn-outline btn-sm btn-danger"
                                onClick={() => handleUpdateStatus(req.id, 'Pending')}
                                title="Reopen your request"
                              >
                                Reopen Request
                              </button>
                            )}

                            {isOwner && (
                              <button
                                type="button"
                                className="btn btn-outline btn-sm btn-danger"
                                onClick={() => handleDeleteRequest(req.id)}
                                title="Permanently delete this request"
                              >
                                Delete
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
