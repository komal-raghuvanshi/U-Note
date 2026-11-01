import { useState, useEffect, useLayoutEffect } from 'react'
import Navbar from './components/Navbar'
import Footer from './components/Footer'
import ShareResource from './components/ShareResource'
import ResourceDetailsModal from './components/ResourceDetailsModal'
import ResourcesPage from './components/ResourcesPage'
import HelpPage from './components/HelpPage'
import ContactPage from './components/ContactPage'
import AuthPages from './components/AuthPages'
import ProfileModal from './components/ProfileModal'
import AboutPage from './components/AboutPage'
import RequestsPage from './components/RequestsPage'
import { apiFetch, apiUrl } from './api'
import './App.css'

function App() {
  const [currentPath, setCurrentPath] = useState(window.location.pathname)
  const [pendingSection, setPendingSection] = useState(() => ({
    id: window.location.hash.slice(1),
  }))
  const [initialCategoryType, setInitialCategoryType] = useState(() => {
    try {
      const searchParams = new URLSearchParams(window.location.search)
      return searchParams.get('type') || ''
    } catch {
      return ''
    }
  })

  const [previewResources, setPreviewResources] = useState([])
  const [loadingPreview, setLoadingPreview] = useState(true)
  const [previewError, setPreviewError] = useState('')
  const [selectedResource, setSelectedResource] = useState(null)
  const [showProfileModal, setShowProfileModal] = useState(false)
  const [profileInitialTab, setProfileInitialTab] = useState('profile')
  const [user, setUser] = useState(() => {
    try {
      const saved = localStorage.getItem('unote_user')
      const parsed = saved ? JSON.parse(saved) : null
      return parsed?.token && parsed?.id ? parsed : null
    } catch {
      return null
    }
  })
  const savedAvatar = user?.avatar

  // Sync route with browser history (Back / Forward)
  useEffect(() => {
    const handleLocationChange = () => {
      setCurrentPath(window.location.pathname)
      const searchParams = new URLSearchParams(window.location.search)
      setInitialCategoryType(searchParams.get('type') || '')
      setPendingSection({ id: window.location.hash.slice(1) })
    }
    window.addEventListener('popstate', handleLocationChange)
    return () => window.removeEventListener('popstate', handleLocationChange)
  }, [])

  useLayoutEffect(() => {
    if (!pendingSection.id) return

    const element = document.getElementById(pendingSection.id)
    if (element) {
      const navbarHeight = document.querySelector('.navbar')?.getBoundingClientRect().height || 0
      const targetTop = window.scrollY + element.getBoundingClientRect().top - navbarHeight - 16
      window.scrollTo({ top: targetTop, behavior: 'smooth' })
    }
  }, [currentPath, pendingSection])

  // Fetch initial sample resources for Homepage preview
  useEffect(() => {
    apiFetch('/resources')
      .then(async (res) => {
        const data = await res.json()
        if (!res.ok) throw new Error(data.message || 'Unable to load featured resources.')
        return data
      })
      .then((data) => {
        setPreviewResources(data.resources || [])
        setLoadingPreview(false)
      })
      .catch((err) => {
        console.error('Error fetching preview resources:', err)
        setPreviewError(err.message || 'Unable to load featured resources.')
        setLoadingPreview(false)
      })
  }, [])

  useEffect(() => {
    if (!user?.token) return undefined

    const controller = new AbortController()
    apiFetch('/profile', { signal: controller.signal }, user.token)
      .then(async (response) => {
        if (response.status === 401) {
          setUser(null)
          localStorage.removeItem('unote_user')
          return
        }
        if (!response.ok) return
        const data = await response.json()
        if (!controller.signal.aborted && data.user) {
          const refreshedUser = { ...data.user, token: user.token, avatar: savedAvatar || '' }
          setUser(refreshedUser)
          localStorage.setItem('unote_user', JSON.stringify(refreshedUser))
        }
      })
      .catch((error) => {
        if (error.name !== 'AbortError') {
          console.error('Unable to refresh the current profile:', error)
        }
      })
    return () => controller.abort()
  }, [user?.token, savedAvatar])

  const navigate = (pathWithQuery, targetSectionId = null) => {
    const destination = new URL(pathWithQuery, window.location.origin)
    window.history.pushState({}, '', destination.pathname + destination.search + destination.hash)
    setCurrentPath(destination.pathname)
    const searchParams = new URLSearchParams(destination.search)
    setInitialCategoryType(searchParams.get('type') || '')

    const sectionId = targetSectionId || destination.hash.slice(1)
    setPendingSection({ id: sectionId || '' })
    if (!sectionId) {
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }
  }

  const handleCategoryClick = (categoryTitle) => {
    navigate(`/resources?type=${encodeURIComponent(categoryTitle)}`)
  }

  const handleLoginSuccess = (userData) => {
    setUser(userData)
    try {
      localStorage.setItem('unote_user', JSON.stringify(userData))
    } catch {
      // ignore
    }
  }

  const handleLogout = () => {
    setUser(null)
    try {
      localStorage.removeItem('unote_user')
    } catch {
      // ignore
    }
  }

  const resourceTypes = [
    {
      title: 'Handwritten Notes',
      description: 'Concise, student-crafted handwritten notes for quick comprehension and exam revision.',
    },
    {
      title: 'PDF Notes',
      description: 'Structured digital notes, syllabus summaries, and textbook references in PDF format.',
    },
    {
      title: 'Previous Year Papers',
      description: 'Past semester examination question papers to practice and understand exam trends.',
    },
    {
      title: 'Important Questions',
      description: 'Curated lists of high-priority questions sorted according to RGPV examination patterns.',
    },
    {
      title: 'YouTube Lectures',
      description: 'Recommended video lectures and complete topic playlists organized unit by unit.',
    },
    {
      title: 'Teacher Resources',
      description: 'Faculty classroom slides, official assignment sets, and verified subject references.',
    },
  ]

  // Render current view based on currentPath
  const renderView = () => {
    switch (currentPath) {
      case '/resources':
        return (
          <ResourcesPage
            key={initialCategoryType}
            initialType={initialCategoryType}
            user={user}
            onSelectResource={(res) => setSelectedResource(res)}
            onShareClick={() => navigate('/share-resource')}
          />
        )

      case '/requests':
        return <RequestsPage user={user} onNavigate={navigate} />

      case '/share-resource':
        return <ShareResource onBack={() => navigate('/')} user={user} />

      case '/help':
        return <HelpPage onNavigate={navigate} />

      case '/contact':
        return <ContactPage />

      case '/about':
        return <AboutPage onNavigate={navigate} />

      case '/login':
        return (
          <AuthPages
            mode="login"
            onNavigate={navigate}
            onLoginSuccess={handleLoginSuccess}
          />
        )

      case '/signup':
        return (
          <AuthPages
            mode="signup"
            onNavigate={navigate}
            onLoginSuccess={handleLoginSuccess}
          />
        )

      case '/':
      default:
        return (
          <>
            {/* 1. Hero Section */}
            <section className="hero-section" id="home">
              <div className="section-container hero-container">
                <h1 className="hero-heading">Find. Learn. Share.</h1>
                <p className="hero-subheading">
                  U-NOTE brings RGPV study resources together in one organized platform.
                </p>
                <div className="hero-button-group">
                  <button
                    type="button"
                    className="btn btn-primary"
                    onClick={() => navigate('/resources')}
                  >
                    Explore Resources
                  </button>

                  <button
                    type="button"
                    className="btn btn-secondary"
                    onClick={() => navigate('/share-resource')}
                  >
                    Share Resources
                  </button>
                </div>
              </div>
            </section>

            {/* 2. Limited Preview of Available Resources */}
            <section className="resources-section" id="resources-preview">
              <div className="section-container">
                <div className="section-header">
                  <h2 className="section-title">Featured Study Resources</h2>
                  <p className="section-description">
                    Quick preview of recently added notes. Visit the dedicated directory to search and filter all materials.
                  </p>
                </div>

                <div className="resources-grid">
                  {previewResources.length > 0 ? (
                    previewResources.slice(0, 4).map((resource) => (
                      <div
                        key={resource.id}
                        className="resource-card"
                        onClick={() => setSelectedResource(resource)}
                        style={{ cursor: 'pointer' }}
                      >
                        <div className="card-top-bar"></div>
                        <h3 className="resource-title">{resource.title}</h3>
                        <p className="resource-description">
                          {resource.branch} · Semester {resource.semester}
                        </p>
                        <p className="resource-description">
                          {resource.subject} · {resource.unit_label || `Unit ${resource.unit}`}
                        </p>
                        <p className="resource-description">{resource.type}</p>
                        <div style={{ marginTop: '0.75rem', display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                          {resource.filename && (
                            <>
                              <a
                                href={apiUrl(`/uploads/${resource.filename}`)}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="btn btn-secondary"
                                style={{ display: 'inline-block', fontSize: '0.82rem', padding: '0.3rem 0.65rem', textDecoration: 'none' }}
                                onClick={(e) => e.stopPropagation()}
                              >
                                View File
                              </a>
                              <a
                                href={apiUrl(`/download/${resource.filename}`)}
                                download
                                className="btn btn-outline"
                                style={{ display: 'inline-block', fontSize: '0.82rem', padding: '0.3rem 0.65rem', textDecoration: 'none' }}
                                onClick={(e) => e.stopPropagation()}
                              >
                                Download
                              </a>
                            </>
                          )}
                          {resource.is_external && resource.resource_url && (
                            <a
                              href={resource.resource_url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="btn btn-secondary"
                              style={{ display: 'inline-block', fontSize: '0.82rem', padding: '0.3rem 0.65rem', textDecoration: 'none' }}
                              onClick={(e) => e.stopPropagation()}
                            >
                              Open Resource &rarr;
                            </a>
                          )}
                        </div>
                      </div>
                    ))
                  ) : (
                    <p className="no-resources-msg">
                      {previewError
                        ? previewError
                        : loadingPreview
                        ? 'Loading resources from backend...'
                        : 'No study resources have been uploaded yet. Be the first to share!'}
                    </p>
                  )}
                </div>

                <div className="view-all-resources-bar">
                  <a
                    href="/resources"
                    className="view-all-text-link"
                    onClick={(e) => {
                      e.preventDefault()
                      navigate('/resources')
                    }}
                  >
                    View All Resources &rarr;
                  </a>
                </div>
              </div>
            </section>

            {/* 3. Supported Resource Types Reference - Clickable Categories */}
            <section className="resources-section" id="resource-types" style={{ backgroundColor: '#ffffff', borderTop: '1px solid var(--border-color)' }}>
              <div className="section-container">
                <div className="section-header">
                  <h2 className="section-title">Supported Resource Types</h2>
                  <p className="section-description">
                    Explore different categories of study resources curated for comprehensive semester preparation. Click any category to view matching materials.
                  </p>
                </div>

                <div className="resources-grid">
                  {resourceTypes.map((typeItem, index) => (
                    <div
                      key={index}
                      className="resource-card category-clickable-card"
                      onClick={() => handleCategoryClick(typeItem.title)}
                      role="button"
                      tabIndex={0}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' || e.key === ' ') {
                          e.preventDefault()
                          handleCategoryClick(typeItem.title)
                        }
                      }}
                      title={`Browse ${typeItem.title}`}
                    >
                      <div className="card-top-bar"></div>
                      <h3 className="resource-title">{typeItem.title}</h3>
                      <p className="resource-description">{typeItem.description}</p>
                    </div>
                  ))}
                </div>
              </div>
            </section>
          </>
        )
    }
  }

  return (
    <div className="app-layout">
      <Navbar
        onNavigate={navigate}
        currentPath={currentPath}
        user={user}
        onOpenProfile={(tab) => {
          setProfileInitialTab(tab || 'profile')
          setShowProfileModal(true)
        }}
        onLogout={handleLogout}
      />

      <main className="main-content">{renderView()}</main>

      {selectedResource && (
        <ResourceDetailsModal
          resource={selectedResource}
          user={user}
          onClose={() => setSelectedResource(null)}
        />
      )}

      {showProfileModal && (
        <ProfileModal
          user={user}
          initialTab={profileInitialTab}
          onClose={() => setShowProfileModal(false)}
          onLogout={handleLogout}
          onNavigate={navigate}
          onUpdateUser={handleLoginSuccess}
        />
      )}

      <Footer onNavigate={navigate} />
    </div>
  )
}

export default App
