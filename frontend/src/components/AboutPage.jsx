function AboutPage({ onNavigate }) {
  const teamMembers = [
    { name: 'Komal Raghuvanshi', initial: 'K' },
    { name: 'Khushi Kushwah', initial: 'K' },
    { name: 'Sakshi Yadav', initial: 'S' },
    { name: 'Vishakha Solanki', initial: 'V' },
  ]

  const features = [
    {
      title: 'Organized Hierarchy',
      description: 'Resources are structured by Branch → Semester → Subject → Unit so you always know where to look.',
    },
    {
      title: 'Student Contributions',
      description: 'Any student can upload notes, papers, or resources to help their batchmates.',
    },
    {
      title: 'Multiple Resource Types',
      description: 'Handwritten notes, PDF notes, previous year papers, important questions, YouTube lectures, and more.',
    },
    {
      title: 'Free to Access',
      description: 'No login required to browse. All resources are freely accessible to every RGPV student.',
    },
  ]

  return (
    <div className="about-page-container">
      {/* Page Header */}
      <div className="page-header-box">
        <div className="page-header-text">
          <h1 className="page-title">About U-NOTE</h1>
          <p className="page-subtitle">
            A student-built platform for RGPV academic resources.
          </p>
        </div>
      </div>

      {/* Section 1: What is U-NOTE */}
      <section className="organization-section">
        <div className="section-container">
          <div className="section-header">
            <h2 className="section-title">What is U-NOTE?</h2>
            <p className="section-description">
              U-NOTE is a student-built academic resource platform designed for RGPV affiliated
              students. Find and share semester notes, PYQs, and study materials organized by
              Branch → Semester → Subject → Unit.
            </p>
          </div>
        </div>
      </section>

      {/* Section 2 & 3: Problem & Solution */}
      <section className="organization-section" style={{ backgroundColor: '#f8fafc' }}>
        <div className="section-container">
          <div className="hierarchy-container">
            <div className="hierarchy-card">
              <span className="hierarchy-step">01</span>
              <h3 className="hierarchy-title">The Problem</h3>
              <p className="hierarchy-text">
                Finding semester notes for RGPV is frustrating. Resources are scattered across
                WhatsApp groups and expiring Drive links. Students waste exam week hunting for
                Unit 3 notes instead of studying them.
              </p>
            </div>

            <div className="hierarchy-arrow">→</div>

            <div className="hierarchy-card">
              <span className="hierarchy-step">02</span>
              <h3 className="hierarchy-title">Our Solution</h3>
              <p className="hierarchy-text">
                U-NOTE brings all academic resources into one organized, searchable platform.
                No login needed to browse. Upload your notes to help batchmates.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Section 4: Key Features */}
      <section className="organization-section">
        <div className="section-container">
          <div className="section-header">
            <h2 className="section-title">Key Features</h2>
            <p className="section-description">
              Everything you need to find and share RGPV study materials.
            </p>
          </div>
          <div className="about-features-grid">
            {features.map((feature, index) => (
              <div key={index} className="about-feature-card">
                <h3 className="hierarchy-title">{feature.title}</h3>
                <p className="hierarchy-text">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Section 5: How It Works */}
      <section className="organization-section" style={{ backgroundColor: '#f8fafc' }}>
        <div className="section-container">
          <div className="section-header">
            <h2 className="section-title">How It Works</h2>
            <p className="section-description">
              Navigate the academic hierarchy to find exactly what you need.
            </p>
          </div>
          <div className="hierarchy-container">
            <div className="hierarchy-card">
              <span className="hierarchy-step">01</span>
              <h3 className="hierarchy-title">Branch</h3>
              <p className="hierarchy-text">Choose your engineering branch — AIML, CSE, IT, EC, ME, or Civil.</p>
            </div>
            <div className="hierarchy-arrow">→</div>
            <div className="hierarchy-card">
              <span className="hierarchy-step">02</span>
              <h3 className="hierarchy-title">Semester</h3>
              <p className="hierarchy-text">Select the semester you're currently studying or preparing for.</p>
            </div>
            <div className="hierarchy-arrow">→</div>
            <div className="hierarchy-card">
              <span className="hierarchy-step">03</span>
              <h3 className="hierarchy-title">Subject</h3>
              <p className="hierarchy-text">Pick the subject from those offered in your branch and semester.</p>
            </div>
            <div className="hierarchy-arrow">→</div>
            <div className="hierarchy-card">
              <span className="hierarchy-step">04</span>
              <h3 className="hierarchy-title">Unit</h3>
              <p className="hierarchy-text">Drill down to the specific unit and get notes, PYQs, or videos.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Section 6: Team */}
      <section className="organization-section">
        <div className="section-container">
          <div className="section-header">
            <h2 className="section-title">Our Team</h2>
            <p className="section-description">
              U-NOTE is developed as Minor Project-I at Jawaharlal Institute of Technology (JIT), Borawan, for RGPV.
            </p>
          </div>
          <div className="about-team-grid">
            {teamMembers.map((member, index) => (
              <div key={index} className="team-member-card">
                <div className="team-avatar">{member.initial}</div>
                <h3 className="hierarchy-title" style={{ marginBottom: '0.25rem', fontSize: '1rem' }}>
                  {member.name}
                </h3>
                <p className="hierarchy-text" style={{ fontSize: '0.82rem' }}>Team Member</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Section 7: CTA */}
      <section className="about-cta-section">
        <div className="section-container">
          <div className="section-header" style={{ marginBottom: '1.5rem' }}>
            <h2 className="section-title">Ready to find your notes?</h2>
            <p className="section-description">
              Browse all available RGPV study resources organized by branch, semester, and subject.
            </p>
          </div>
          <div style={{ textAlign: 'center' }}>
            <button
              type="button"
              className="btn btn-primary"
              onClick={() => onNavigate('/resources')}
            >
              Explore Resources
            </button>
          </div>
        </div>
      </section>
    </div>
  )
}

export default AboutPage
