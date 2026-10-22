import { useState, useEffect } from 'react'
import Navbar from './components/Navbar'
import Footer from './components/Footer'
import ShareResource from './components/ShareResource'
import ResourceDetailsModal from './components/ResourceDetailsModal'
import ResourcesPage from './components/ResourcesPage'
import HelpPage from './components/HelpPage'
import ContactPage from './components/ContactPage'
import AuthPages from './components/AuthPages'
import ProfileModal from './components/ProfileModal'
import './App.css'

function App() {
  const [currentPath, setCurrentPath] = useState(window.location.pathname)
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
  const [selectedResource, setSelectedResource] = useState(null)
  const [showProfileModal, setShowProfileModal] = useState(false)
  const [user, setUser] = useState(() => {
    try {
      const saved = localStorage.getItem('unote_user')
      return saved ? JSON.parse(saved) : null
    } catch {
      return null
    }
  })

  // Sync route with browser history (Back / Forward)
  useEffect(() => {
    const handleLocationChange = () => {
      setCurrentPath(window.location.pathname)
      const searchParams = new URLSearchParams(window.location.search)
      setInitialCategoryType(searchParams.get('type') || '')
    }
    window.addEventListener('popstate', handleLocationChange)
    return () => window.removeEventListener('popstate', handleLocationChange)
  }, [])

  // Fetch initial sample resources for Homepage preview
  useEffect(() => {
    fetch('http://127.0.0.1:5000/resources')
      .then((res) => res.json())
      .then((data) => {
        setPreviewResources(data.resources || [])
        setLoadingPreview(false)
      })
      .catch((err) => {
        console.error('Error fetching preview resources:', err)
        setLoadingPreview(false)
      })
  }, [])

  const navigate = (pathWithQuery, targetSectionId = null) => {
    window.history.pushState({}, '', pathWithQuery)
    const [pathOnly, queryString] = pathWithQuery.split('?')
    setCurrentPath(pathOnly)
    const searchParams = new URLSearchParams(queryString ? `?${queryString}` : '')
    setInitialCategoryType(searchParams.get('type') || '')

    if (targetSectionId) {
      setTimeout(() => {
        const element = document.getElementById(targetSectionId)
        if (element) {
          element.scrollIntoView({ behavior: 'smooth' })
        }
      }, 50)
    } else {
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
            onSelectResource={(res) => setSelectedResource(res)}
            onShareClick={() => navigate('/share-resource')}
          />
        )

      case '/share-resource':
        return <ShareResource onBack={() => navigate('/')} user={user} />

      case '/help':
        return <HelpPage onNavigate={navigate} />

      case '/contact':
        return <ContactPage />

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

            {/* 2. How Resources Are Organized */}
            <section className="organization-section" id="about">
              <div className="section-container">
                <div className="section-header">
                  <h2 className="section-title">How Resources Are Organized</h2>
                  <p className="section-description">
                    Say goodbye to scattered links across multiple apps. In U-NOTE, resources are
                    structured systematically following the official RGPV academic hierarchy so you
                    can locate the exact material you need.
                  </p>
                </div>

                <div className="hierarchy-container">
                  <div className="hierarchy-card">
                    <span className="hierarchy-step">Step 1</span>
                    <h3 className="hierarchy-title">Branch</h3>
                    <p className="hierarchy-text">Choose your engineering discipline (e.g., AIML, CSE, IT, EC, ME, Civil).</p>
                  </div>

                  <div className="hierarchy-arrow" aria-hidden="true">&rarr;</div>

                  <div className="hierarchy-card">
                    <span className="hierarchy-step">Step 2</span>
                    <h3 className="hierarchy-title">Semester</h3>
                    <p className="hierarchy-text">Select your current semester from 1st through 8th.</p>
                  </div>

                  <div className="hierarchy-arrow" aria-hidden="true">&rarr;</div>

                  <div className="hierarchy-card">
                    <span className="hierarchy-step">Step 3</span>
                    <h3 className="hierarchy-title">Subject</h3>
                    <p className="hierarchy-text">Pick your course subject according to the RGPV curriculum.</p>
                  </div>

                  <div className="hierarchy-arrow" aria-hidden="true">&rarr;</div>

                  <div className="hierarchy-card">
                    <span className="hierarchy-step">Step 4</span>
                    <h3 className="hierarchy-title">Unit</h3>
                    <p className="hierarchy-text">Access focused unit-wise study material (Units 1 to 5).</p>
                  </div>
                </div>
              </div>
            </section>

            {/* 3. Limited Preview of Available Resources */}
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
                          {resource.subject} · Unit {resource.unit}
                        </p>
                        <p className="resource-description">{resource.type}</p>
                        {resource.filename && (
                          <div style={{ marginTop: '0.75rem' }}>
                            <a
                              href={`http://127.0.0.1:5000/uploads/${resource.filename}`}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="btn btn-secondary"
                              style={{ display: 'inline-block', fontSize: '0.85rem', padding: '0.35rem 0.75rem', textDecoration: 'none' }}
                              onClick={(e) => e.stopPropagation()}
                            >
                              View PDF
                            </a>
                          </div>
                        )}
                      </div>
                    ))
                  ) : (
                    <p className="no-resources-msg">
                      {loadingPreview
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

            {/* 4. Supported Resource Types Reference - Clickable Categories */}
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
        onOpenProfile={() => setShowProfileModal(true)}
        onLogout={handleLogout}
      />

      <main className="main-content">{renderView()}</main>

      {selectedResource && (
        <ResourceDetailsModal
          resource={selectedResource}
          onClose={() => setSelectedResource(null)}
        />
      )}

      {showProfileModal && (
        <ProfileModal
          user={user}
          onClose={() => setShowProfileModal(false)}
          onLogout={handleLogout}
          onNavigate={navigate}
          onUpdateUser={handleLoginSuccess}
        />
      )}

      <Footer />
    </div>
  )
}

export default App
