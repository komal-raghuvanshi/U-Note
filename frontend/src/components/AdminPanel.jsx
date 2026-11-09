import { useState, useEffect, useCallback } from 'react'
import { apiFetch } from '../api'

function AdminPanel({ user, onNavigate }) {
  const [activeTab, setActiveTab] = useState('dashboard') // 'dashboard', 'users', 'resources', 'reports', 'requests'
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [successMsg, setSuccessMsg] = useState('')

  // Dashboard Stats State
  const [stats, setStats] = useState(null)
  const [recentActivities, setRecentActivities] = useState([])

  // Users Tab State
  const [usersList, setUsersList] = useState([])
  const [userSearch, setUserSearch] = useState('')
  const [userRoleFilter, setUserRoleFilter] = useState('')

  // Resources Tab State
  const [resourcesList, setResourcesList] = useState([])
  const [resSearch, setResSearch] = useState('')
  const [resApprovalFilter, setResApprovalFilter] = useState('')

  // Reports Tab State
  const [reportsList, setReportsList] = useState([])
  const [reportStatusFilter, setReportStatusFilter] = useState('pending')
  const [selectedReport, setSelectedReport] = useState(null)
  const [reportAdminNotes, setReportAdminNotes] = useState('')

  // Requests Tab State
  const [requestsList, setRequestsList] = useState([])
  const [requestStatusFilter, setRequestStatusFilter] = useState('')

  const isAdmin = user?.role === 'admin'

  const showNotification = (msg) => {
    setSuccessMsg(msg)
    setTimeout(() => setSuccessMsg(''), 4000)
  }

  // Load Dashboard Stats
  const loadDashboardStats = useCallback(async () => {
    if (!user?.token) return
    setLoading(true)
    setError('')
    try {
      const res = await apiFetch('/admin/stats', {}, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        setStats(data.stats)
        setRecentActivities(data.recent_activities || [])
      } else {
        setError(data.message || 'Unable to load dashboard stats.')
      }
    } catch {
      setError('Network error while loading stats.')
    } finally {
      setLoading(false)
    }
  }, [user])

  // Load Users
  const loadUsers = useCallback(async () => {
    if (!user?.token) return
    setLoading(true)
    setError('')
    try {
      const params = new URLSearchParams()
      if (userSearch) params.set('search', userSearch)
      if (userRoleFilter) params.set('role', userRoleFilter)

      const res = await apiFetch(`/admin/users?${params.toString()}`, {}, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        setUsersList(data.users || [])
      } else {
        setError(data.message || 'Unable to load user accounts.')
      }
    } catch {
      setError('Network error while loading users.')
    } finally {
      setLoading(false)
    }
  }, [user, userSearch, userRoleFilter])

  // Load Resources
  const loadResources = useCallback(async () => {
    if (!user?.token) return
    setLoading(true)
    setError('')
    try {
      const params = new URLSearchParams()
      if (resSearch) params.set('search', resSearch)
      if (resApprovalFilter) params.set('approval_status', resApprovalFilter)

      const res = await apiFetch(`/admin/resources?${params.toString()}`, {}, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        setResourcesList(data.resources || [])
      } else {
        setError(data.message || 'Unable to load resources.')
      }
    } catch {
      setError('Network error while loading resources.')
    } finally {
      setLoading(false)
    }
  }, [user, resSearch, resApprovalFilter])

  // Load Reports
  const loadReports = useCallback(async () => {
    if (!user?.token) return
    setLoading(true)
    setError('')
    try {
      const params = new URLSearchParams()
      if (reportStatusFilter) params.set('status', reportStatusFilter)

      const res = await apiFetch(`/admin/reports?${params.toString()}`, {}, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        setReportsList(data.reports || [])
      } else {
        setError(data.message || 'Unable to load reports.')
      }
    } catch {
      setError('Network error while loading reports.')
    } finally {
      setLoading(false)
    }
  }, [user, reportStatusFilter])

  // Load Requests
  const loadRequests = useCallback(async () => {
    if (!user?.token) return
    setLoading(true)
    setError('')
    try {
      const params = new URLSearchParams()
      if (requestStatusFilter) params.set('status', requestStatusFilter)

      const res = await apiFetch(`/admin/requests?${params.toString()}`, {}, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        setRequestsList(data.requests || [])
      } else {
        setError(data.message || 'Unable to load requests.')
      }
    } catch {
      setError('Network error while loading requests.')
    } finally {
      setLoading(false)
    }
  }, [user, requestStatusFilter])

  useEffect(() => {
    if (!isAdmin) return
    if (activeTab === 'dashboard') loadDashboardStats()
    else if (activeTab === 'users') loadUsers()
    else if (activeTab === 'resources') loadResources()
    else if (activeTab === 'reports') loadReports()
    else if (activeTab === 'requests') loadRequests()
  }, [isAdmin, activeTab, loadDashboardStats, loadUsers, loadResources, loadReports, loadRequests])

  // Action handlers
  const handleToggleBlockUser = async (targetUser) => {
    const action = targetUser.is_blocked ? 'unblock' : 'block'
    if (!window.confirm(`Are you sure you want to ${action} ${targetUser.name}?`)) return
    try {
      const res = await apiFetch(`/admin/users/${targetUser.user_id}/block`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_blocked: !targetUser.is_blocked })
      }, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        showNotification(data.message || `User successfully ${action}ed.`)
        loadUsers()
      } else {
        alert(data.message || `Failed to ${action} user.`)
      }
    } catch {
      alert(`Network error while trying to ${action} user.`)
    }
  }

  const handleChangeUserRole = async (targetUserId, newRole) => {
    try {
      const res = await apiFetch(`/admin/users/${targetUserId}/role`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ role: newRole })
      }, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        showNotification(data.message || `User role updated to ${newRole}.`)
        loadUsers()
      } else {
        alert(data.message || 'Failed to update user role.')
      }
    } catch {
      alert('Network error while updating role.')
    }
  }

  const handleToggleApproval = async (resourceId, newStatus) => {
    try {
      const res = await apiFetch(`/admin/resources/${resourceId}/approval`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ approval_status: newStatus })
      }, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        showNotification(data.message || `Resource status set to ${newStatus}.`)
        loadResources()
      } else {
        alert(data.message || 'Failed to update resource approval.')
      }
    } catch {
      alert('Network error while updating approval.')
    }
  }

  const handleToggleVerify = async (resourceId, currentVerified) => {
    try {
      const res = await apiFetch(`/admin/resources/${resourceId}/verify`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_verified: !currentVerified })
      }, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        showNotification(data.message || 'Verification status updated.')
        loadResources()
      } else {
        alert(data.message || 'Failed to update verification status.')
      }
    } catch {
      alert('Network error while updating verification.')
    }
  }

  const handleDeleteResource = async (resourceId, title) => {
    if (!window.confirm(`Are you sure you want to delete the resource "${title}"? This cannot be undone.`)) return
    try {
      const res = await apiFetch(`/admin/resources/${resourceId}`, {
        method: 'DELETE'
      }, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        showNotification(data.message || 'Resource deleted.')
        loadResources()
      } else {
        alert(data.message || 'Failed to delete resource.')
      }
    } catch {
      alert('Network error while deleting resource.')
    }
  }

  const handleUpdateReportStatus = async (reportId, status, notes = '') => {
    try {
      const res = await apiFetch(`/admin/reports/${reportId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status, admin_notes: notes })
      }, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        showNotification(data.message || `Report marked as ${status}.`)
        setSelectedReport(null)
        setReportAdminNotes('')
        loadReports()
      } else {
        alert(data.message || 'Failed to update report.')
      }
    } catch {
      alert('Network error while updating report.')
    }
  }

  const handleUpdateRequestStatus = async (requestId, newStatus) => {
    try {
      const res = await apiFetch(`/admin/requests/${requestId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus })
      }, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        showNotification(data.message || `Request status set to ${newStatus}.`)
        loadRequests()
      } else {
        alert(data.message || 'Failed to update request status.')
      }
    } catch {
      alert('Network error while updating request.')
    }
  }

  if (!user) {
    return (
      <div className="section-container" style={{ padding: '4rem 1rem', textAlign: 'center' }}>
        <h2>Authentication Required</h2>
        <p style={{ color: 'var(--text-muted)', margin: '1rem 0' }}>Please log in with an administrator account to access the Admin Panel.</p>
        <button type="button" className="btn btn-primary" onClick={() => onNavigate('/login')}>
          Go to Login
        </button>
      </div>
    )
  }

  if (!isAdmin) {
    return (
      <div className="section-container" style={{ padding: '4rem 1rem', textAlign: 'center' }}>
        <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>🛡️</div>
        <h2>Access Restricted</h2>
        <p style={{ color: '#ef4444', margin: '1rem 0', fontWeight: 500 }}>
          Your account does not have administrator privileges. Only authorized U-NOTE admins can access this dashboard.
        </p>
        <button type="button" className="btn btn-primary" onClick={() => onNavigate('/')}>
          Return to Home
        </button>
      </div>
    )
  }

  return (
    <div className="admin-page" style={{ minHeight: '80vh', padding: '2rem 1rem', background: 'var(--bg-light)' }}>
      <div className="section-container" style={{ maxWidth: '1200px', margin: '0 auto' }}>
        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1.5rem', flexWrap: 'wrap', gap: '1rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
              <span style={{ fontSize: '1.6rem' }}>⚙️</span>
              <h1 style={{ fontSize: '1.75rem', fontWeight: 700, margin: 0, color: 'var(--text-dark)' }}>Admin Dashboard</h1>
            </div>
            <p style={{ margin: '0.25rem 0 0', color: 'var(--text-muted)', fontSize: '0.92rem' }}>
              Manage users, study materials, student reports, and request fulfillment.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-outline"
            onClick={() => onNavigate('/')}
            style={{ fontSize: '0.88rem' }}
          >
            &larr; Back to App
          </button>
        </div>

        {/* Global Success / Alert Banner */}
        {successMsg && (
          <div className="alert-banner alert-success" style={{ marginBottom: '1.25rem' }}>
            {successMsg}
          </div>
        )}
        {error && (
          <div className="alert-banner alert-danger" style={{ marginBottom: '1.25rem' }}>
            {error}
          </div>
        )}

        {/* Admin Navigation Tabs */}
        <div className="admin-tabs" style={{ display: 'flex', gap: '0.5rem', borderBottom: '2px solid var(--border-color)', marginBottom: '1.5rem', overflowX: 'auto', paddingBottom: '2px' }}>
          {[
            { id: 'dashboard', label: '📊 Dashboard Overview' },
            { id: 'users', label: '👥 User Accounts' },
            { id: 'resources', label: '📚 Study Resources' },
            { id: 'reports', label: '🚩 Student Reports' },
            { id: 'requests', label: '📋 Note Requests' }
          ].map((tab) => (
            <button
              key={tab.id}
              type="button"
              className={`admin-tab-btn ${activeTab === tab.id ? 'active' : ''}`}
              onClick={() => setActiveTab(tab.id)}
              style={{
                padding: '0.65rem 1.15rem',
                border: 'none',
                background: activeTab === tab.id ? '#6366f1' : 'transparent',
                color: activeTab === tab.id ? '#ffffff' : 'var(--text-secondary)',
                fontWeight: 600,
                borderRadius: '8px 8px 0 0',
                cursor: 'pointer',
                whiteSpace: 'nowrap',
                transition: 'all 0.15s ease'
              }}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* TAB 1: DASHBOARD OVERVIEW */}
        {activeTab === 'dashboard' && (
          <div>
            {/* Metric Cards Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem', marginBottom: '2rem' }}>
              <div style={{ background: 'var(--card-bg)', borderRadius: '12px', padding: '1.25rem', boxShadow: '0 1px 3px rgba(0,0,0,0.08)', border: '1px solid var(--border-color)' }}>
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: 600 }}>TOTAL USERS</span>
                <div style={{ fontSize: '1.85rem', fontWeight: 800, color: 'var(--text-dark)', marginTop: '0.25rem' }}>
                  {stats ? stats.total_users : '...'}
                </div>
              </div>

              <div style={{ background: 'var(--card-bg)', borderRadius: '12px', padding: '1.25rem', boxShadow: '0 1px 3px rgba(0,0,0,0.08)', border: '1px solid var(--border-color)' }}>
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: 600 }}>RESOURCES</span>
                <div style={{ fontSize: '1.85rem', fontWeight: 800, color: '#6366f1', marginTop: '0.25rem' }}>
                  {stats ? stats.total_resources : '...'}
                </div>
              </div>

              <div style={{ background: 'var(--card-bg)', borderRadius: '12px', padding: '1.25rem', boxShadow: '0 1px 3px rgba(0,0,0,0.08)', border: '1px solid var(--border-color)' }}>
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: 600 }}>PENDING APPROVALS</span>
                <div style={{ fontSize: '1.85rem', fontWeight: 800, color: '#f59e0b', marginTop: '0.25rem' }}>
                  {stats ? stats.pending_approvals : '...'}
                </div>
              </div>

              <div style={{ background: 'var(--card-bg)', borderRadius: '12px', padding: '1.25rem', boxShadow: '0 1px 3px rgba(0,0,0,0.08)', border: '1px solid var(--border-color)' }}>
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: 600 }}>PENDING REPORTS</span>
                <div style={{ fontSize: '1.85rem', fontWeight: 800, color: '#ef4444', marginTop: '0.25rem' }}>
                  {stats ? stats.pending_reports : '...'}
                </div>
              </div>

              <div style={{ background: 'var(--card-bg)', borderRadius: '12px', padding: '1.25rem', boxShadow: '0 1px 3px rgba(0,0,0,0.08)', border: '1px solid var(--border-color)' }}>
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontWeight: 600 }}>RESOURCE REQUESTS</span>
                <div style={{ fontSize: '1.85rem', fontWeight: 800, color: '#0ea5e9', marginTop: '0.25rem' }}>
                  {stats ? stats.total_requests : '...'}
                </div>
              </div>
            </div>

            {/* Recent Platform Activities */}
            <div style={{ background: 'var(--card-bg)', borderRadius: '12px', padding: '1.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.08)', border: '1px solid var(--border-color)' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1rem' }}>
                <h2 style={{ fontSize: '1.15rem', fontWeight: 700, margin: 0, color: 'var(--text-dark)' }}>Recent Platform Activity</h2>
                <button type="button" className="btn btn-secondary" onClick={loadDashboardStats} style={{ fontSize: '0.8rem', padding: '0.3rem 0.75rem' }}>
                  Refresh
                </button>
              </div>

              {recentActivities.length === 0 ? (
                <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', margin: '1rem 0' }}>No recent activity records available.</p>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                  {recentActivities.map((act, idx) => (
                    <div
                      key={idx}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        padding: '0.65rem 0.85rem',
                        background: 'var(--bg-light)',
                        borderRadius: '8px',
                        fontSize: '0.9rem'
                      }}
                    >
                      <span style={{ color: '#334155' }}>
                        {act.type === 'report' ? '🚩 ' : '📤 '}
                        {act.text}
                      </span>
                      <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                        {act.created_at ? new Date(act.created_at).toLocaleString('en-IN') : ''}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        {/* TAB 2: USER MANAGEMENT */}
        {activeTab === 'users' && (
          <div style={{ background: 'var(--card-bg)', borderRadius: '12px', padding: '1.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.08)', border: '1px solid var(--border-color)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '1rem', marginBottom: '1.25rem' }}>
              <h2 style={{ fontSize: '1.15rem', fontWeight: 700, margin: 0, color: 'var(--text-dark)' }}>
                Registered Users ({usersList.length})
              </h2>

              <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
                <input
                  type="text"
                  placeholder="Search name or email..."
                  value={userSearch}
                  onChange={(e) => setUserSearch(e.target.value)}
                  className="form-control"
                  style={{ width: '220px', fontSize: '0.85rem', padding: '0.4rem 0.75rem' }}
                />
                <select
                  value={userRoleFilter}
                  onChange={(e) => setUserRoleFilter(e.target.value)}
                  className="form-control"
                  style={{ width: '130px', fontSize: '0.85rem', padding: '0.4rem 0.75rem' }}
                >
                  <option value="">All Roles</option>
                  <option value="student">Student</option>
                  <option value="teacher">Teacher</option>
                  <option value="admin">Admin</option>
                </select>
                <button type="button" className="btn btn-secondary" onClick={loadUsers} style={{ fontSize: '0.85rem', padding: '0.4rem 0.75rem' }}>
                  Filter
                </button>
              </div>
            </div>

            {loading ? (
              <p style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem 0' }}>Loading user accounts...</p>
            ) : usersList.length === 0 ? (
              <p style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem 0' }}>No users match the search filters.</p>
            ) : (
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.88rem', textAlign: 'left' }}>
                  <thead>
                    <tr style={{ background: 'var(--bg-secondary)', color: 'var(--text-secondary)', borderBottom: '2px solid var(--border-color)' }}>
                      <th style={{ padding: '0.75rem 1rem' }}>User</th>
                      <th style={{ padding: '0.75rem 1rem' }}>Academic Info</th>
                      <th style={{ padding: '0.75rem 1rem' }}>Role</th>
                      <th style={{ padding: '0.75rem 1rem' }}>Uploads</th>
                      <th style={{ padding: '0.75rem 1rem' }}>Status</th>
                      <th style={{ padding: '0.75rem 1rem', textAlign: 'right' }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {usersList.map((u) => (
                      <tr key={u.user_id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                        <td style={{ padding: '0.75rem 1rem' }}>
                          <strong style={{ display: 'block', color: 'var(--text-dark)' }}>{u.name}</strong>
                          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{u.email}</span>
                        </td>
                        <td style={{ padding: '0.75rem 1rem', color: 'var(--text-secondary)' }}>
                          {u.branch || 'General'} · {u.semester || 'N/A'}
                        </td>
                        <td style={{ padding: '0.75rem 1rem' }}>
                          <select
                            value={u.role || 'student'}
                            onChange={(e) => handleChangeUserRole(u.user_id, e.target.value)}
                            disabled={u.user_id === user.id}
                            style={{
                              fontSize: '0.8rem',
                              padding: '0.25rem 0.5rem',
                              borderRadius: '6px',
                              border: '1px solid #cbd5e1',
                              fontWeight: 600,
                              background: u.role === 'admin' ? '#ede9fe' : u.role === 'teacher' ? '#e0f2fe' : '#ffffff'
                            }}
                          >
                            <option value="student">Student</option>
                            <option value="teacher">Teacher</option>
                            <option value="admin">Admin</option>
                          </select>
                        </td>
                        <td style={{ padding: '0.75rem 1rem', color: 'var(--text-secondary)' }}>
                          {u.uploads_count || 0}
                        </td>
                        <td style={{ padding: '0.75rem 1rem' }}>
                          {u.is_blocked ? (
                            <span style={{ background: '#fee2e2', color: '#ef4444', fontSize: '0.75rem', fontWeight: 700, padding: '0.2rem 0.5rem', borderRadius: '6px' }}>
                              Blocked
                            </span>
                          ) : (
                            <span style={{ background: '#d1fae5', color: '#059669', fontSize: '0.75rem', fontWeight: 700, padding: '0.2rem 0.5rem', borderRadius: '6px' }}>
                              Active
                            </span>
                          )}
                        </td>
                        <td style={{ padding: '0.75rem 1rem', textAlign: 'right' }}>
                          {u.user_id !== user.id && (
                            <button
                              type="button"
                              className={`btn ${u.is_blocked ? 'btn-secondary' : 'btn-outline'}`}
                              onClick={() => handleToggleBlockUser(u)}
                              style={{
                                fontSize: '0.75rem',
                                padding: '0.3rem 0.65rem',
                                color: u.is_blocked ? '#059669' : '#ef4444',
                                borderColor: u.is_blocked ? '#a7f3d0' : '#fca5a5'
                              }}
                            >
                              {u.is_blocked ? 'Unblock' : 'Block'}
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* TAB 3: RESOURCE MANAGEMENT */}
        {activeTab === 'resources' && (
          <div style={{ background: 'var(--card-bg)', borderRadius: '12px', padding: '1.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.08)', border: '1px solid var(--border-color)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '1rem', marginBottom: '1.25rem' }}>
              <h2 style={{ fontSize: '1.15rem', fontWeight: 700, margin: 0, color: 'var(--text-dark)' }}>
                Study Resources ({resourcesList.length})
              </h2>

              <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
                <input
                  type="text"
                  placeholder="Search resources..."
                  value={resSearch}
                  onChange={(e) => setResSearch(e.target.value)}
                  className="form-control"
                  style={{ width: '220px', fontSize: '0.85rem', padding: '0.4rem 0.75rem' }}
                />
                <select
                  value={resApprovalFilter}
                  onChange={(e) => setResApprovalFilter(e.target.value)}
                  className="form-control"
                  style={{ width: '150px', fontSize: '0.85rem', padding: '0.4rem 0.75rem' }}
                >
                  <option value="">All Statuses</option>
                  <option value="approved">Approved</option>
                  <option value="pending">Pending Review</option>
                  <option value="rejected">Rejected</option>
                </select>
                <button type="button" className="btn btn-secondary" onClick={loadResources} style={{ fontSize: '0.85rem', padding: '0.4rem 0.75rem' }}>
                  Filter
                </button>
              </div>
            </div>

            {loading ? (
              <p style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem 0' }}>Loading resources...</p>
            ) : resourcesList.length === 0 ? (
              <p style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem 0' }}>No resources match the selected criteria.</p>
            ) : (
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.88rem', textAlign: 'left' }}>
                  <thead>
                    <tr style={{ background: 'var(--bg-secondary)', color: 'var(--text-secondary)', borderBottom: '2px solid var(--border-color)' }}>
                      <th style={{ padding: '0.75rem 1rem' }}>Resource Title</th>
                      <th style={{ padding: '0.75rem 1rem' }}>Subject & Course</th>
                      <th style={{ padding: '0.75rem 1rem' }}>Uploaded By</th>
                      <th style={{ padding: '0.75rem 1rem' }}>Rating / Badges</th>
                      <th style={{ padding: '0.75rem 1rem' }}>Approval</th>
                      <th style={{ padding: '0.75rem 1rem', textAlign: 'right' }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {resourcesList.map((res) => (
                      <tr key={res.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                        <td style={{ padding: '0.75rem 1rem' }}>
                          <strong style={{ display: 'block', color: 'var(--text-dark)' }}>{res.title}</strong>
                          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{res.type}</span>
                        </td>
                        <td style={{ padding: '0.75rem 1rem', color: 'var(--text-secondary)' }}>
                          {res.subject || 'N/A'} · {res.branch} Sem {res.semester}
                        </td>
                        <td style={{ padding: '0.75rem 1rem', color: 'var(--text-secondary)' }}>
                          {res.uploader_name || 'Community'}
                        </td>
                        <td style={{ padding: '0.75rem 1rem' }}>
                          <div style={{ display: 'flex', gap: '0.35rem', flexWrap: 'wrap', alignItems: 'center' }}>
                            <span style={{ fontSize: '0.8rem', fontWeight: 600, color: '#f59e0b' }}>
                              ★ {res.avg_rating ? res.avg_rating.toFixed(1) : '—'} ({res.rating_count || 0})
                            </span>
                            {res.is_verified ? (
                              <span style={{ background: '#e0e7ff', color: '#4338ca', fontSize: '0.72rem', fontWeight: 700, padding: '0.15rem 0.4rem', borderRadius: '4px' }}>
                                Verified
                              </span>
                            ) : null}
                          </div>
                        </td>
                        <td style={{ padding: '0.75rem 1rem' }}>
                          <select
                            value={res.approval_status || 'approved'}
                            onChange={(e) => handleToggleApproval(res.id, e.target.value)}
                            style={{
                              fontSize: '0.8rem',
                              padding: '0.2rem 0.45rem',
                              borderRadius: '6px',
                              border: '1px solid #cbd5e1',
                              fontWeight: 600,
                              background: res.approval_status === 'approved' ? '#d1fae5' : res.approval_status === 'rejected' ? '#fee2e2' : '#fef3c7'
                            }}
                          >
                            <option value="approved">Approved</option>
                            <option value="pending">Pending</option>
                            <option value="rejected">Rejected</option>
                          </select>
                        </td>
                        <td style={{ padding: '0.75rem 1rem', textAlign: 'right' }}>
                          <div style={{ display: 'flex', gap: '0.4rem', justifyContent: 'flex-end' }}>
                            <button
                              type="button"
                              className={`btn ${res.is_verified ? 'btn-secondary' : 'btn-outline'}`}
                              onClick={() => handleToggleVerify(res.id, res.is_verified)}
                              style={{ fontSize: '0.75rem', padding: '0.25rem 0.55rem' }}
                              title="Toggle Verified Quality Badge"
                            >
                              {res.is_verified ? 'Unverify' : 'Verify'}
                            </button>
                            <button
                              type="button"
                              className="btn btn-outline"
                              onClick={() => handleDeleteResource(res.id, res.title)}
                              style={{ fontSize: '0.75rem', padding: '0.25rem 0.55rem', color: '#ef4444', borderColor: '#fca5a5' }}
                            >
                              Delete
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* TAB 4: REPORT MANAGEMENT */}
        {activeTab === 'reports' && (
          <div style={{ background: 'var(--card-bg)', borderRadius: '12px', padding: '1.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.08)', border: '1px solid var(--border-color)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '1rem', marginBottom: '1.25rem' }}>
              <h2 style={{ fontSize: '1.15rem', fontWeight: 700, margin: 0, color: 'var(--text-dark)' }}>
                Student Reports ({reportsList.length})
              </h2>

              <div style={{ display: 'flex', gap: '0.75rem' }}>
                <select
                  value={reportStatusFilter}
                  onChange={(e) => setReportStatusFilter(e.target.value)}
                  className="form-control"
                  style={{ width: '150px', fontSize: '0.85rem', padding: '0.4rem 0.75rem' }}
                >
                  <option value="">All Reports</option>
                  <option value="pending">Pending</option>
                  <option value="resolved">Resolved</option>
                  <option value="rejected">Dismissed</option>
                </select>
                <button type="button" className="btn btn-secondary" onClick={loadReports} style={{ fontSize: '0.85rem', padding: '0.4rem 0.75rem' }}>
                  Filter
                </button>
              </div>
            </div>

            {loading ? (
              <p style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem 0' }}>Loading reports...</p>
            ) : reportsList.length === 0 ? (
              <p style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem 0' }}>No reports under this filter.</p>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                {reportsList.map((rep) => (
                  <div
                    key={rep.report_id}
                    style={{
                      border: '1px solid var(--border-color)',
                      borderRadius: '8px',
                      padding: '1rem',
                      background: rep.status === 'pending' ? '#fffaf0' : '#ffffff'
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '0.5rem', flexWrap: 'wrap', gap: '0.5rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <span style={{
                          background: rep.status === 'pending' ? '#fef3c7' : rep.status === 'resolved' ? '#d1fae5' : '#fee2e2',
                          color: rep.status === 'pending' ? '#b45309' : rep.status === 'resolved' ? '#065f46' : '#991b1b',
                          fontSize: '0.75rem',
                          fontWeight: 700,
                          padding: '0.2rem 0.5rem',
                          borderRadius: '4px'
                        }}>
                          {rep.status.toUpperCase()}
                        </span>
                        <strong style={{ color: 'var(--text-dark)', fontSize: '0.95rem' }}>
                          Reason: {rep.reason}
                        </strong>
                      </div>
                      <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                        {rep.created_at ? new Date(rep.created_at).toLocaleString('en-IN') : ''}
                      </span>
                    </div>

                    <p style={{ margin: '0.25rem 0', fontSize: '0.88rem', color: 'var(--text-secondary)' }}>
                      <strong>Resource:</strong> {rep.resource_title || `Resource #${rep.resource_id}`} &nbsp;|&nbsp;
                      <strong>Reported by:</strong> {rep.reporter_name} ({rep.reporter_email})
                    </p>

                    {rep.details && (
                      <div style={{ background: 'var(--bg-light)', padding: '0.5rem 0.75rem', borderRadius: '6px', fontSize: '0.85rem', color: '#334155', margin: '0.5rem 0' }}>
                        <em>"{rep.details}"</em>
                      </div>
                    )}

                    {rep.admin_notes && (
                      <p style={{ fontSize: '0.8rem', color: '#6366f1', margin: '0.35rem 0' }}>
                        <strong>Admin Notes:</strong> {rep.admin_notes}
                      </p>
                    )}

                    {rep.status === 'pending' && (
                      <div style={{ display: 'flex', gap: '0.5rem', marginTop: '0.75rem', alignItems: 'center', flexWrap: 'wrap' }}>
                        <button
                          type="button"
                          className="btn btn-primary"
                          onClick={() => {
                            setSelectedReport(rep)
                            setReportAdminNotes('')
                          }}
                          style={{ fontSize: '0.8rem', padding: '0.35rem 0.75rem' }}
                        >
                          Resolve / Dismiss
                        </button>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}

            {/* Resolve Modal */}
            {selectedReport && (
              <div className="modal-overlay" onClick={() => setSelectedReport(null)} role="dialog" aria-modal="true">
                <div className="modal-card" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '480px' }}>
                  <button type="button" className="modal-close-icon" onClick={() => setSelectedReport(null)}>&times;</button>
                  <h3 style={{ margin: '0 0 0.75rem', fontSize: '1.2rem', color: 'var(--text-dark)' }}>
                    Process Report #{selectedReport.report_id}
                  </h3>
                  <p style={{ fontSize: '0.88rem', color: 'var(--text-secondary)', marginBottom: '1rem' }}>
                    Resource: <strong>{selectedReport.resource_title}</strong>
                  </p>

                  <div className="form-group" style={{ marginBottom: '1rem' }}>
                    <label style={{ display: 'block', fontWeight: 600, fontSize: '0.85rem', marginBottom: '0.35rem' }}>
                      Admin Notes (sent to reporter)
                    </label>
                    <textarea
                      className="form-control"
                      rows={3}
                      placeholder="e.g. File has been removed or checked and validated..."
                      value={reportAdminNotes}
                      onChange={(e) => setReportAdminNotes(e.target.value)}
                    />
                  </div>

                  <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end' }}>
                    <button
                      type="button"
                      className="btn btn-secondary"
                      onClick={() => handleUpdateReportStatus(selectedReport.report_id, 'rejected', reportAdminNotes)}
                      style={{ fontSize: '0.85rem' }}
                    >
                      Dismiss Report
                    </button>
                    <button
                      type="button"
                      className="btn btn-primary"
                      onClick={() => handleUpdateReportStatus(selectedReport.report_id, 'resolved', reportAdminNotes)}
                      style={{ fontSize: '0.85rem' }}
                    >
                      Mark Resolved
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* TAB 5: NOTE REQUESTS MANAGEMENT */}
        {activeTab === 'requests' && (
          <div style={{ background: 'var(--card-bg)', borderRadius: '12px', padding: '1.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.08)', border: '1px solid var(--border-color)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '1rem', marginBottom: '1.25rem' }}>
              <h2 style={{ fontSize: '1.15rem', fontWeight: 700, margin: 0, color: 'var(--text-dark)' }}>
                Student Requests ({requestsList.length})
              </h2>

              <div style={{ display: 'flex', gap: '0.75rem' }}>
                <select
                  value={requestStatusFilter}
                  onChange={(e) => setRequestStatusFilter(e.target.value)}
                  className="form-control"
                  style={{ width: '150px', fontSize: '0.85rem', padding: '0.4rem 0.75rem' }}
                >
                  <option value="">All Statuses</option>
                  <option value="Pending">Pending</option>
                  <option value="In Progress">In Progress</option>
                  <option value="Fulfilled">Fulfilled</option>
                  <option value="Closed">Closed</option>
                </select>
                <button type="button" className="btn btn-secondary" onClick={loadRequests} style={{ fontSize: '0.85rem', padding: '0.4rem 0.75rem' }}>
                  Filter
                </button>
              </div>
            </div>

            {loading ? (
              <p style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem 0' }}>Loading requests...</p>
            ) : requestsList.length === 0 ? (
              <p style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem 0' }}>No student requests found.</p>
            ) : (
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.88rem', textAlign: 'left' }}>
                  <thead>
                    <tr style={{ background: 'var(--bg-secondary)', color: 'var(--text-secondary)', borderBottom: '2px solid var(--border-color)' }}>
                      <th style={{ padding: '0.75rem 1rem' }}>Request Title</th>
                      <th style={{ padding: '0.75rem 1rem' }}>Requested By</th>
                      <th style={{ padding: '0.75rem 1rem' }}>Course / Branch</th>
                      <th style={{ padding: '0.75rem 1rem' }}>Status</th>
                      <th style={{ padding: '0.75rem 1rem', textAlign: 'right' }}>Update Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {requestsList.map((req) => (
                      <tr key={req.request_id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                        <td style={{ padding: '0.75rem 1rem' }}>
                          <strong style={{ display: 'block', color: 'var(--text-dark)' }}>{req.title}</strong>
                          {req.description && (
                            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{req.description.slice(0, 60)}...</span>
                          )}
                        </td>
                        <td style={{ padding: '0.75rem 1rem', color: 'var(--text-secondary)' }}>
                          {req.user_name || 'Student'}
                        </td>
                        <td style={{ padding: '0.75rem 1rem', color: 'var(--text-secondary)' }}>
                          {req.branch || 'General'} · {req.semester || 'N/A'}
                        </td>
                        <td style={{ padding: '0.75rem 1rem' }}>
                          <span style={{
                            background: req.status === 'Fulfilled' ? '#d1fae5' : req.status === 'In Progress' ? '#e0f2fe' : req.status === 'Closed' ? '#f1f5f9' : '#fef3c7',
                            color: req.status === 'Fulfilled' ? '#065f46' : req.status === 'In Progress' ? '#0369a1' : req.status === 'Closed' ? '#475569' : '#b45309',
                            fontSize: '0.75rem',
                            fontWeight: 700,
                            padding: '0.2rem 0.5rem',
                            borderRadius: '4px'
                          }}>
                            {req.status}
                          </span>
                        </td>
                        <td style={{ padding: '0.75rem 1rem', textAlign: 'right' }}>
                          <select
                            value={req.status}
                            onChange={(e) => handleUpdateRequestStatus(req.request_id, e.target.value)}
                            style={{
                              fontSize: '0.8rem',
                              padding: '0.2rem 0.45rem',
                              borderRadius: '6px',
                              border: '1px solid #cbd5e1'
                            }}
                          >
                            <option value="Pending">Pending</option>
                            <option value="In Progress">In Progress</option>
                            <option value="Fulfilled">Fulfilled</option>
                            <option value="Closed">Closed</option>
                          </select>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}

export default AdminPanel
