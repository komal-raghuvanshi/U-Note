import Navbar from './components/Navbar'
import Footer from './components/Footer'
import './App.css'

function App() {
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

  return (
    <div className="app-layout">
      <Navbar />

      <main className="main-content">
        {/* 1. Hero Section */}
        <section className="hero-section" id="home">
          <div className="section-container hero-container">
            <span className="hero-badge">RGPV Academic Portal</span>
            <h1 className="hero-heading">Find. Learn. Share.</h1>
            <p className="hero-subheading">
              U-NOTE brings RGPV study resources together in one organized platform.
            </p>
            <div className="hero-button-group">
              <button type="button" className="btn btn-primary">
                Explore Resources
              </button>
              <button type="button" className="btn btn-secondary">
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
                <p className="hierarchy-text">Choose your engineering discipline (e.g., CSE, IT, ME, EC, Civil).</p>
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

        {/* 3. Resource Types */}
        <section className="resources-section" id="resources">
          <div className="section-container">
            <div className="section-header">
              <h2 className="section-title">Resource Types</h2>
              <p className="section-description">
                Explore different types of study resources curated for comprehensive semester preparation.
              </p>
            </div>

            <div className="resources-grid">
              {resourceTypes.map((resource, index) => (
                <div key={index} className="resource-card">
                  <div className="card-top-bar"></div>
                  <h3 className="resource-title">{resource.title}</h3>
                  <p className="resource-description">{resource.description}</p>
                </div>
              ))}
            </div>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  )
}

export default App


