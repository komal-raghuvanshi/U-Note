import { useState, useEffect } from 'react'

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

  // Edit form state
  const [editName, setEditName] = useState(user.name || '')
  const [editBranch, setEditBranch] = useState(user.branch || 'AIML')
  const [editSemester, setEditSemester] = useState(user.semester || 4)
  const [editAvatar, setEditAvatar] = useState(user.avatar || '')

  useEffect(() => {
    if (activeTab !== 'shared') return

    if (!user?.id) {
      setSharedResources([])
      setSharedResourcesError('Unable to load shared resources for this account.')
      return
    }

    const controller = new AbortController()
    async function fetchSharedResources() {
      setSharedResourcesLoading(true)
      setSharedResourcesError('')

      try {
        const params = new URLSearchParams({ user_id: String(user.id) })
        const response = await fetch(
          `http://127.0.0.1:5000/resources/shared?${params.toString()}`,
          { signal: controller.signal }
        )
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
  }, [activeTab, user?.id])

  if (!user) return null

  const handleStartEdit = () => {
    setEditName(user.name || '')
    setEditBranch(user.branch || 'AIML')
    setEditSemester(user.semester || 4)
    setEditAvatar(user.avatar || '')
    setIsEditing(true)
  }

  const handleCancelEdit = () => {
    setIsEditing(false)
  }

  const handleFileChange = (e) => {
    const file = e.target.files[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (event) => {
        setEditAvatar(event.target.result)
      }
      reader.readAsDataURL(file)
    }
  }

  const handleSaveProfile = (e) => {
    e.preventDefault()
    const updated = {
      ...user,
      name: editName.trim() || user.name,
      branch: editBranch,
      semester: Number(editSemester),
      avatar: editAvatar
    }
    if (onUpdateUser) {
      onUpdateUser(updated)
    }
    setIsEditing(false)
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
            {user.avatar ? (
              <img src={user.avatar} alt={user.name} className="profile-avatar-img-large" />
            ) : (
              <span>{user.name.charAt(0).toUpperCase()}</span>
            )}
          </div>
          <div className="profile-header-info">
            <h2 className="profile-modal-name">{user.name}</h2>
            <p className="profile-modal-email">{user.email}</p>
            <span className="profile-badge-tag">{user.branch} · Semester {user.semester}</span>
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
              My Shared Resources
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
              <div className="prototype-badge-box">
                <span className="prototype-badge-pill">Session Storage</span>
                <p className="prototype-badge-text">
                  Profile edits are saved for your current browsing session. Permanent database sync will connect with the backend.
                </p>
              </div>

              {/* Avatar Selection */}
              <div className="avatar-picker-section">
                <label className="avatar-picker-label">Choose Avatar or Upload Photo</label>

                {/* Built-in Avatars Grid */}
                <div className="avatar-options-grid">
                  {BUILT_IN_AVATARS.map((av) => (
                    <button
                      key={av.id}
                      type="button"
                      className={`avatar-option-btn ${editAvatar === av.src ? 'selected' : ''}`}
                      onClick={() => setEditAvatar(av.src)}
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
                    accept="image/*"
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

              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="edit-branch">Branch</label>
                  <select
                    id="edit-branch"
                    className="form-control"
                    value={editBranch}
                    onChange={(e) => setEditBranch(e.target.value)}
                  >
                    <option value="AIML">AIML</option>
                    <option value="CSE">CSE</option>
                    <option value="IT">IT</option>
                    <option value="EC">EC</option>
                    <option value="ME">ME</option>
                    <option value="Civil">Civil</option>
                  </select>
                </div>

                <div className="form-group">
                  <label htmlFor="edit-semester">Semester</label>
                  <select
                    id="edit-semester"
                    className="form-control"
                    value={editSemester}
                    onChange={(e) => setEditSemester(e.target.value)}
                  >
                    {[1, 2, 3, 4, 5, 6, 7, 8].map((s) => (
                      <option key={s} value={s}>
                        Semester {s}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="edit-actions-row">
                <button type="submit" className="btn btn-primary">
                  Save Changes
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
                    <span className="meta-label">College Affiliation</span>
                    <span className="meta-value">RGPV Affiliated College</span>
                  </div>
                  <div className="meta-item">
                    <span className="meta-label">Branch</span>
                    <span className="meta-value">{user.branch}</span>
                  </div>
                  <div className="meta-item">
                    <span className="meta-label">Current Semester</span>
                    <span className="meta-value">Semester {user.semester}</span>
                  </div>
                </div>
              )}

              {activeTab === 'shared' && (
                <div className="profile-tab-content profile-shared-content">
                  {sharedResourcesLoading ? (
                    <p className="empty-tab-text" role="status">Loading your shared resources...</p>
                  ) : sharedResourcesError ? (
                    <p className="error-message" role="alert">{sharedResourcesError}</p>
                  ) : sharedResources.length === 0 ? (
                    <>
                      <p className="empty-tab-text">You haven't shared any resources yet.</p>
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
                        <article className="resource-card" key={resource.id}>
                          <div className="card-top-bar"></div>
                          <h3 className="resource-title">{resource.title}</h3>
                          <p className="resource-description">
                            {resource.branch} · Semester {resource.semester}
                          </p>
                          <p className="resource-description">
                            {resource.subject} · {resource.unit_label}
                          </p>
                          <p className="resource-description">{resource.type}</p>
                          {resource.uploaded_at && (
                            <p className="resource-description">
                              Uploaded {new Date(resource.uploaded_at).toLocaleDateString()}
                            </p>
                          )}
                          {resource.filename && (
                            <a
                              href={`http://127.0.0.1:5000/uploads/${resource.filename}`}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="btn btn-secondary"
                            >
                              View Resource
                            </a>
                          )}
                        </article>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {activeTab === 'saved' && (
                <div className="profile-tab-content">
                  <p className="empty-tab-text">
                    Bookmark and save unit notes directly from the Resources page for quick pre-exam revision.
                  </p>
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
