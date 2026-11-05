import { useState, useEffect } from 'react'
import { apiFetch, apiUrl } from '../api'
import { useAcademicOptions } from '../hooks/useAcademicOptions'

const BUILT_IN_AVATARS = [
  { id: 'avatar1', label: 'Tech Student', src: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="50" fill="%232563eb"/><circle cx="50" cy="40" r="20" fill="%23ffd1b3"/><path d="M50 20c-14 0-22 8-22 18 0 4 2 8 5 10 1-5 4-8 10-10 4 1 10 1 14 0 6 2 9 5 10 10 3-2 5-6 5-10 0-10-8-18-22-18z" fill="%23374151"/><circle cx="43" cy="42" r="6" fill="none" stroke="%231e293b" stroke-width="2"/><circle cx="57" cy="42" r="6" fill="none" stroke="%231e293b" stroke-width="2"/><path d="M49 42h2" stroke="%231e293b" stroke-width="2"/><path d="M45 52c3 2 7 2 10 0" fill="none" stroke="%23e11d48" stroke-width="2" stroke-linecap="round"/><path d="M22 88c5-16 16-24 28-24s23 8 28 24" fill="%231e40af"/></svg>' },
  { id: 'avatar2', label: 'Audio Scholar', src: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="50" fill="%23059669"/><circle cx="50" cy="42" r="20" fill="%23fed7aa"/><path d="M50 22c-12 0-20 7-20 16 0 4 3 8 5 9 1-4 4-7 9-8 4 1 8 1 12 0 5 1 8 4 9 8 2-1 5-5 5-9 0-9-8-16-20-16z" fill="%2392400e"/><path d="M26 40c0-14 10-24 24-24s24 10 24 24" fill="none" stroke="%231f2937" stroke-width="4"/><rect x="23" y="36" width="7" height="15" rx="3" fill="%23111827"/><rect x="70" y="36" width="7" height="15" rx="3" fill="%23111827"/><circle cx="43" cy="43" r="2.5" fill="%231f2937"/><circle cx="57" cy="43" r="2.5" fill="%231f2937"/><path d="M46 52c2 1 6 1 8 0" fill="none" stroke="%23ea580c" stroke-width="2" stroke-linecap="round"/><path d="M20 90c6-18 17-26 30-26s24 8 30 26" fill="%23047857"/></svg>' },
  { id: 'avatar3', label: 'Graduate', src: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="50" fill="%237c3aed"/><circle cx="50" cy="44" r="20" fill="%23fcd34d"/><polygon points="50,14 78,24 50,34 22,24" fill="%231e293b"/><path d="M30 30v12c0 6 9 10 20 10s20-4 20-10V30" fill="%231e293b"/><path d="M72 26v16" stroke="%23fbbf24" stroke-width="2"/><circle cx="72" cy="44" r="3" fill="%23f59e0b"/><circle cx="44" cy="45" r="2.5" fill="%23111827"/><circle cx="56" cy="45" r="2.5" fill="%23111827"/><path d="M46 54c2 1 6 1 8 0" fill="none" stroke="%23dc2626" stroke-width="2" stroke-linecap="round"/><path d="M22 92c5-18 16-26 28-26s23 8 28 26" fill="%236d28d9"/></svg>' },
  { id: 'avatar4', label: 'Coder', src: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="50" fill="%23ea580c"/><circle cx="50" cy="42" r="20" fill="%23ffedd5"/><path d="M30 34c4-12 12-16 20-16s16 4 20 16c-6 2-13 3-20 3s-14-1-20-3z" fill="%231f2937"/><path d="M22 34h56l-6 6H28z" fill="%23374151"/><circle cx="43" cy="44" r="2.5" fill="%231f2937"/><circle cx="57" cy="44" r="2.5" fill="%231f2937"/><path d="M45 52c3 2 7 2 10 0" fill="none" stroke="%23c2410c" stroke-width="2" stroke-linecap="round"/><path d="M20 90c5-17 17-25 30-25s25 8 30 25" fill="%23c2410c"/></svg>' }
]

function ProfileModal({ user, initialTab = 'profile', onClose, onLogout, onNavigate, onUpdateUser }) {
  const [activeTab, setActiveTab] = useState(initialTab)
  const [isEditing, setIsEditing] = useState(false)
  const [sharedResources, setSharedResources] = useState([])
  const [sharedResourcesLoading, setSharedResourcesLoading] = useState(false)
  const [sharedResourcesError, setSharedResourcesError] = useState('')
  const [savedResources, setSavedResources] = useState([])
  const [savedResourcesError, setSavedResourcesError] = useState('')
  const [deletingId, setDeletingId] = useState(null)
  const [savingProfile, setSavingProfile] = useState(false)
  const [profileError, setProfileError] = useState('')
  const [profilePhotoFile, setProfilePhotoFile] = useState(null)
  const [avatarFailed, setAvatarFailed] = useState(false)

  // Edit form state
  const [editName, setEditName] = useState(user?.name || '')
  const [editBranch, setEditBranch] = useState(user?.branch || '')
  const [editSemester, setEditSemester] = useState(user?.semester || '')
  const [editAvatar, setEditAvatar] = useState(user?.avatar || '')
  useEffect(() => {
    setAvatarFailed(false)
  }, [user?.avatar])
  const { branches, semesters, branchesLoading, semestersLoading } =
    useAcademicOptions(editBranch, editSemester)
  const roleLabel = user?.role === 'teacher'
    ? 'Teacher'
    : user?.role === 'student' ? 'Student' : 'Member'

  useEffect(() => {
    if (activeTab !== 'shared') return

    if (!user?.id) {
      setSharedResources([])
      setSharedResourcesError('Unable to load shared resources. Please log in again.')
      return
    }

    const controller = new AbortController()
    async function fetchSharedResources() {
      setSharedResourcesLoading(true)
      setSharedResourcesError('')

      try {
        const response = await apiFetch('/resources/shared', { signal: controller.signal }, user.token)
        const result = await response.json()
        if (!response.ok) {
          throw new Error(result.message || 'Unable to load shared resources.')
        }
        setSharedResources(Array.isArray(result.resources) ? result.resources : [])
      } catch (error) {
        if (error.name !== 'AbortError') {
          setSharedResourcesError(error.message || 'Unable to load shared resources.')
        }
      } finally {
        if (!controller.signal.aborted) {
          setSharedResourcesLoading(false)
        }
      }
    }

    fetchSharedResources()
    return () => controller.abort()
  }, [activeTab, user?.id, user?.token])

  useEffect(() => {
    if (activeTab !== 'saved') return undefined

    const controller = new AbortController()
    async function fetchSavedResources() {
      setSavedResourcesError('')
      try {
        const response = await apiFetch('/resources/saved', { signal: controller.signal }, user.token)
        const data = await response.json()
        if (!response.ok) throw new Error(data.message || 'Unable to load saved resources.')
        if (!controller.signal.aborted) {
          setSavedResources(Array.isArray(data.resources) ? data.resources : [])
        }
      } catch (error) {
        if (error.name !== 'AbortError') {
          setSavedResourcesError(error.message || 'Unable to load saved resources.')
        }
      }
    }

    fetchSavedResources()
    return () => controller.abort()
  }, [activeTab, user?.token])

  if (!user) return null

  const handleStartEdit = () => {
    setEditName(user.name || '')
    setEditBranch(user.branch || '')
    setEditSemester(user.semester || '')
    setEditAvatar(user.avatar || '')
    setProfilePhotoFile(null)
    setIsEditing(true)
  }

  const handleCancelEdit = () => {
    setIsEditing(false)
    setProfilePhotoFile(null)
    setEditAvatar(user.avatar || '')
    setProfileError('')
  }

  const handleFileChange = (e) => {
    const file = e.target.files[0]
    if (file) {
      const extension = file.name.split('.').pop()?.toLowerCase()
      if (!['jpg', 'jpeg', 'png', 'webp'].includes(extension) || file.size > 5 * 1024 * 1024) {
        setProfileError('Choose a JPG, PNG, or WEBP image no larger than 5 MB.')
        e.target.value = ''
        return
      }
      setProfilePhotoFile(file)
      setProfileError('')
      const reader = new FileReader()
      reader.onload = (event) => {
        setEditAvatar(event.target.result)
      }
      reader.readAsDataURL(file)
    }
  }

  const handleSaveProfile = async (e) => {
    e.preventDefault()
    setProfileError('')
    setSavingProfile(true)
    try {
      const profileData = new FormData()
      profileData.append('name', editName.trim())
      if (user.role !== 'teacher') {
        profileData.append('branch', editBranch)
        profileData.append('semester', String(Number(editSemester)))
      }
      if (profilePhotoFile) {
        profileData.append('profile_photo', profilePhotoFile)
      } else if (editAvatar.startsWith('data:image/svg+xml')) {
        profileData.append('remove_profile_photo', '1')
      }
      const response = await apiFetch('/profile', {
        method: 'PUT',
        body: profileData
      }, user.token)
      const data = await response.json()
      if (!response.ok) throw new Error(data.message || 'Unable to save profile changes.')
      if (onUpdateUser) {
        onUpdateUser({
          ...data.user,
          token: user.token,
          avatar: data.user.profile_photo_url
            ? apiUrl(data.user.profile_photo_url)
            : profilePhotoFile ? '' : editAvatar
        })
      }
      setProfilePhotoFile(null)
      setIsEditing(false)
    } catch (error) {
      setProfileError(error.message || 'Unable to save profile changes.')
    } finally {
      setSavingProfile(false)
    }
  }

  const handleDeleteResource = async (resourceId, title) => {
    if (!window.confirm(`Are you sure you want to delete "${title}"?`)) {
      return
    }

    setDeletingId(resourceId)
    try {
      const response = await apiFetch(`/resources/${resourceId}`, { method: 'DELETE' }, user.token)
      const data = await response.json()
      if (!response.ok) {
        throw new Error(data.message || 'Failed to delete resource.')
      }

      setSharedResources((prev) => prev.filter((r) => r.id !== resourceId))
    } catch (err) {
      alert(err.message || 'Error deleting resource.')
    } finally {
      setDeletingId(null)
    }
  }

  return (
    <div className="modal-overlay" onClick={onClose} role="dialog" aria-modal="true">
      <div className="modal-card profile-modal-card" onClick={(e) => e.stopPropagation()}>
        <button
          type="button"
          className="modal-close-icon"
          onClick={onClose}
          aria-label="Close modal"
        >
          &times;
        </button>

        {/* Profile Header */}
        <div className="profile-modal-header">
          <div className="profile-avatar-large">
            {user.avatar && !avatarFailed ? (
              <img
                src={user.avatar}
                alt={user.name}
                className="profile-avatar-img-large"
                onError={() => setAvatarFailed(true)}
              />
            ) : (
              <span>{(user.name || 'U').charAt(0).toUpperCase()}</span>
            )}
          </div>
          <div className="profile-header-info">
            <h2 className="profile-modal-name">{user.name}</h2>
            <p className="profile-modal-email">{user.email}</p>
            <div className="profile-identity-badges">
              <span className={`role-badge role-badge-${user.role || 'member'}`}>
                {roleLabel}
              </span>
              {user.role !== 'teacher' && user.branch && user.semester && (
                <span className="profile-badge-tag">{user.branch} · Semester {user.semester}</span>
              )}
            </div>
          </div>

          {!isEditing && activeTab === 'profile' && (
            <button
              type="button"
              className="btn btn-secondary edit-profile-btn"
              onClick={handleStartEdit}
            >
              Edit Profile
            </button>
          )}
        </div>

        {/* Profile Tabs (only visible when not editing) */}
        {!isEditing && (
          <div className="profile-tabs-nav">
            <button
              type="button"
              className={`profile-tab-btn ${activeTab === 'profile' ? 'active' : ''}`}
              onClick={() => setActiveTab('profile')}
            >
              My Profile
            </button>
            <button
              type="button"
              className={`profile-tab-btn ${activeTab === 'shared' ? 'active' : ''}`}
              onClick={() => setActiveTab('shared')}
            >
              My Shared Resources {sharedResources.length > 0 && `(${sharedResources.length})`}
            </button>
            <button
              type="button"
              className={`profile-tab-btn ${activeTab === 'saved' ? 'active' : ''}`}
              onClick={() => setActiveTab('saved')}
            >
              Saved Resources
            </button>
          </div>
        )}

        <div className="profile-modal-body">
          {isEditing ? (
            /* Edit Profile Form */
            <form className="profile-edit-form" onSubmit={handleSaveProfile}>
              <div className="avatar-picker-section">
                <label className="avatar-picker-label">Choose Avatar or Upload Photo</label>

                {/* Built-in Avatars Grid */}
                <div className="avatar-options-grid">
                  {BUILT_IN_AVATARS.map((av) => (
                    <button
                      key={av.id}
                      type="button"
                      className={`avatar-option-btn ${editAvatar === av.src ? 'selected' : ''}`}
                      onClick={() => {
                        setEditAvatar(av.src)
                        setProfilePhotoFile(null)
                      }}
                      title={av.label}
                    >
                      <img src={av.src} alt={av.label} className="avatar-option-img" />
                    </button>
                  ))}
                </div>

                {/* Custom File Upload Option */}
                <div className="avatar-file-upload">
                  <label htmlFor="avatar-file-input" className="file-upload-label">
                    Or upload custom picture from device:
                  </label>
                  <input
                    type="file"
                    id="avatar-file-input"
                    accept=".jpg,.jpeg,.png,.webp"
                    className="form-control file-input"
                    onChange={handleFileChange}
                  />
                </div>
              </div>

              {/* Text Fields */}
              <div className="form-group">
                <label htmlFor="edit-name">Display Name</label>
                <input
                  type="text"
                  id="edit-name"
                  className="form-control"
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  required
                />
              </div>

              {user.role !== 'teacher' && <div className="form-row">
                <div className="form-group">
                  <label htmlFor="edit-branch">Branch</label>
                  <select
                    id="edit-branch"
                    className="form-control"
                    value={editBranch}
                    required
                    onChange={(e) => {
                      setEditBranch(e.target.value)
                      setEditSemester('')
                    }}
                  >
                    <option value="">Select branch</option>
                    {branches.map((branch) => (
                      <option key={branch.id} value={branch.name}>{branch.name}</option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label htmlFor="edit-semester">Semester</label>
                  <select
                    id="edit-semester"
                    className="form-control"
                    value={editSemester}
                    onChange={(e) => setEditSemester(e.target.value)}
                    required
                    disabled={!editBranch || semestersLoading || branchesLoading}
                  >
                    <option value="">
                      {!editBranch
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
              </div>}

              {profileError && <p className="error-message" role="alert">{profileError}</p>}

              <div className="edit-actions-row">
                <button type="submit" className="btn btn-primary" disabled={savingProfile}>
                  {savingProfile ? 'Saving...' : 'Save Changes'}
                </button>
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={handleCancelEdit}
                >
                  Cancel
                </button>
              </div>
            </form>
          ) : (
            /* View Mode */
            <>
              {activeTab === 'profile' && (
                <div className="modal-meta-grid">
                  <div className="meta-item">
                    <span className="meta-label">Full Name</span>
                    <span className="meta-value">{user.name}</span>
                  </div>
                  <div className="meta-item">
                    <span className="meta-label">Role</span>
                    <span className="meta-value">
                      {roleLabel}
                    </span>
                  </div>
                  {user.role !== 'teacher' && (
                    <div className="meta-item">
                    <span className="meta-label">Branch</span>
                    <span className="meta-value">{user.branch}</span>
                    </div>
                  )}
                  {user.role !== 'teacher' && (
                    <div className="meta-item">
                    <span className="meta-label">Current Semester</span>
                    <span className="meta-value">Semester {user.semester}</span>
                    </div>
                  )}
                </div>
              )}

              {activeTab === 'shared' && (
                <div className="profile-tab-content profile-shared-content">
                  {sharedResourcesLoading ? (
                    <p className="empty-tab-text" role="status">Loading your shared resources from MySQL...</p>
                  ) : sharedResourcesError ? (
                    <p className="error-message" role="alert">{sharedResourcesError}</p>
                  ) : sharedResources.length === 0 ? (
                    <>
                      <p className="empty-tab-text">You haven't shared any study resources yet.</p>
                      <button
                        type="button"
                        className="btn btn-primary"
                        onClick={() => {
                          onClose()
                          onNavigate('/share-resource')
                        }}
                      >
                        Share a Study Resource
                      </button>
                    </>
                  ) : (
                    <div className="profile-shared-resources">
                      {sharedResources.map((resource) => (
                        <article className="resource-card" key={resource.id} style={{ marginBottom: '1rem' }}>
                          <div className="card-top-bar"></div>
                          <h3 className="resource-title">{resource.title}</h3>
                          <p className="resource-description">
                            {resource.branch} · Semester {resource.semester}
                          </p>
                          <p className="resource-description">
                            {resource.subject} · {resource.unit_label || `Unit ${resource.unit}`}
                          </p>
                          <p className="resource-description">{resource.type}</p>
                          {resource.uploaded_at && (
                            <p className="resource-description" style={{ fontSize: '0.8rem', color: '#64748b' }}>
                              Uploaded: {new Date(resource.uploaded_at).toLocaleDateString()}
                            </p>
                          )}
                          <div style={{ marginTop: '0.75rem', display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                            {resource.filename && (
                              <>
                                <a
                                  href={apiUrl(`/uploads/${resource.filename}`)}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="btn btn-secondary"
                                  style={{ fontSize: '0.8rem', padding: '0.3rem 0.65rem' }}
                                >
                                  View File
                                </a>
                                <a
                                  href={apiUrl(`/download/${resource.filename}`)}
                                  download
                                  className="btn btn-outline"
                                  style={{ fontSize: '0.8rem', padding: '0.3rem 0.65rem' }}
                                >
                                  Download
                                </a>
                              </>
                            )}
                            <button
                              type="button"
                              className="btn btn-outline-danger"
                              style={{ fontSize: '0.8rem', padding: '0.3rem 0.65rem', marginLeft: 'auto' }}
                              disabled={deletingId === resource.id}
                              onClick={() => handleDeleteResource(resource.id, resource.title)}
                            >
                              {deletingId === resource.id ? 'Deleting...' : 'Delete'}
                            </button>
                          </div>
                        </article>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {activeTab === 'saved' && (
                <div className="profile-tab-content">
                  {savedResourcesError ? (
                    <p className="error-message" role="alert">{savedResourcesError}</p>
                  ) : savedResources.length === 0 ? (
                    <>
                      <p className="empty-tab-text">You haven't saved any study resources yet.</p>
                      <button
                        type="button"
                        className="btn btn-secondary"
                        onClick={() => {
                          onClose()
                          onNavigate('/resources')
                        }}
                      >
                        Browse Resources
                      </button>
                    </>
                  ) : (
                    <div className="profile-shared-resources">
                      {savedResources.map((resource) => (
                        <article className="resource-card" key={resource.id} style={{ marginBottom: '1rem' }}>
                          <div className="card-top-bar"></div>
                          <h3 className="resource-title">{resource.title}</h3>
                          <p className="resource-description">
                            {resource.branch} · Semester {resource.semester} · {resource.subject}
                          </p>
                          <p className="resource-description">{resource.unit_label} · {resource.type}</p>
                          {resource.filename && (
                            <a className="btn btn-secondary" href={apiUrl(`/download/${resource.filename}`)} download>
                              Download
                            </a>
                          )}
                          {resource.is_external && (
                            <a className="btn btn-secondary" href={resource.resource_url} target="_blank" rel="noopener noreferrer">
                              Open Resource
                            </a>
                          )}
                        </article>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </>
          )}
        </div>

        {!isEditing && (
          <div className="modal-footer profile-modal-footer">
            <button
              type="button"
              className="btn btn-outline logout-btn"
              onClick={() => {
                onLogout()
                onClose()
              }}
            >
              Log Out
            </button>
            <button type="button" className="btn btn-primary" onClick={onClose}>
              Done
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

export default ProfileModal
