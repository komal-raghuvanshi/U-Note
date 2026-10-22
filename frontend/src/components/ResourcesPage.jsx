import { useState, useEffect, useCallback } from 'react'

function ResourcesPage({ onSelectResource, onShareClick, initialType = '' }) {
  const [resources, setResources] = useState([])
  const [loading, setLoading] = useState(true)
  const [visibleCount, setVisibleCount] = useState(6)

  // Filters state initialized with initialType
  const [search, setSearch] = useState('')
  const [branch, setBranch] = useState('')
  const [semester, setSemester] = useState('')
  const [subject, setSubject] = useState('')
  const [unit, setUnit] = useState('')
  const [type, setType] = useState(initialType)

  const loadResources = useCallback((queryOverride = {}) => {
    setLoading(true)
    const activeSearch = queryOverride.search !== undefined ? queryOverride.search : search
    const activeBranch = queryOverride.branch !== undefined ? queryOverride.branch : branch
    const activeSemester = queryOverride.semester !== undefined ? queryOverride.semester : semester
    const activeSubject = queryOverride.subject !== undefined ? queryOverride.subject : subject
    const activeUnit = queryOverride.unit !== undefined ? queryOverride.unit : unit
    const activeType = queryOverride.type !== undefined ? queryOverride.type : type

    const params = new URLSearchParams()
    if (activeSearch && activeSearch.trim()) params.append('search', activeSearch.trim())
    if (activeBranch) params.append('branch', activeBranch)
    if (activeSemester) params.append('semester', activeSemester)
    if (activeSubject && activeSubject.trim()) params.append('subject', activeSubject.trim())
    if (activeUnit) params.append('unit', activeUnit)
    if (activeType) params.append('type', activeType)

    const url = `http://127.0.0.1:5000/resources?${params.toString()}`

    fetch(url)
      .then((res) => res.json())
      .then((data) => {
        setResources(data.resources || [])
        setLoading(false)
        setVisibleCount(6)
      })
      .catch((err) => {
        console.error('Error fetching resources:', err)
        setLoading(false)
      })
  }, [search, branch, semester, subject, unit, type])

  // Initial load respecting initialType
  useEffect(() => {
    let ignore = false
    const params = new URLSearchParams()
    if (initialType) params.append('type', initialType)

    const url = `http://127.0.0.1:5000/resources?${params.toString()}`

    fetch(url)
      .then((res) => res.json())
      .then((data) => {
        if (!ignore) {
          setResources(data.resources || [])
          setLoading(false)
        }
      })
      .catch((err) => {
        if (!ignore) {
          console.error('Error fetching resources:', err)
          setLoading(false)
        }
      })
    return () => {
      ignore = true
    }
  }, [initialType])

  const handleBranchChange = (newBranch) => {
    setBranch(newBranch)
    loadResources({ branch: newBranch })
  }

  const handleSemesterChange = (newSemester) => {
    setSemester(newSemester)
    loadResources({ semester: newSemester })
  }

  const handleSubjectChange = (newSubject) => {
    setSubject(newSubject)
    loadResources({ subject: newSubject })
  }

  const handleUnitChange = (newUnit) => {
    setUnit(newUnit)
    loadResources({ unit: newUnit })
  }

  const handleTypeChange = (newType) => {
    setType(newType)
    loadResources({ type: newType })
  }

  const handleSearchSubmit = (e) => {
    e.preventDefault()
    loadResources()
  }

  const handleResetFilters = () => {
    setSearch('')
    setBranch('')
    setSemester('')
    setSubject('')
    setUnit('')
    setType('')
    loadResources({
      search: '',
      branch: '',
      semester: '',
      subject: '',
      unit: '',
      type: ''
    })
  }

  const visibleResources = resources.slice(0, visibleCount)

  return (
    <div className="resources-page-container">
      <div className="section-container">
        {/* Page Header */}
        <div className="page-header-box">
          <div className="page-header-text">
            <h1 className="page-title">RGPV Study Resources</h1>
            <p className="page-subtitle">
              Browse, filter, and discover unit-wise notes, previous year papers, and academic materials.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={onShareClick}
          >
            + Share a Resource
          </button>
        </div>

        {/* Filter and Search Bar */}
        <div className="filters-card">
          <form className="search-form" onSubmit={handleSearchSubmit}>
            <div className="search-input-wrapper">
              <input
                type="text"
                className="form-control search-input"
                placeholder="Search notes, subjects, or topics by title..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
              <button type="submit" className="btn btn-primary search-btn">
                Search
              </button>
            </div>
          </form>

          <div className="filters-grid">
            <div className="filter-item">
              <label htmlFor="filter-branch">Branch</label>
              <select
                id="filter-branch"
                className="form-control"
                value={branch}
                onChange={(e) => handleBranchChange(e.target.value)}
              >
                <option value="">All Branches</option>
                <option value="AIML">AIML</option>
                <option value="CSE">CSE</option>
                <option value="IT">IT</option>
                <option value="EC">EC</option>
                <option value="ME">ME</option>
                <option value="Civil">Civil</option>
              </select>
            </div>

            <div className="filter-item">
              <label htmlFor="filter-semester">Semester</label>
              <select
                id="filter-semester"
                className="form-control"
                value={semester}
                onChange={(e) => handleSemesterChange(e.target.value)}
              >
                <option value="">All Semesters</option>
                {[1, 2, 3, 4, 5, 6, 7, 8].map((s) => (
                  <option key={s} value={s}>
                    Semester {s}
                  </option>
                ))}
              </select>
            </div>

            
            <div className="filter-item">
              <label htmlFor="filter-subject">Subject</label>
              <select
                id="filter-subject"
                className="form-control"
                value={subject}
                onChange={(e) => handleSubjectChange(e.target.value)}
              >
                <option value="">All Subjects</option>
                <option value="Artificial Intelligence">
                  Artificial Intelligence
                </option>
                <option value="Machine Learning">
                  Machine Learning
                </option>
                <option value="Software Engineering">
                  Software Engineering
                </option>
              </select>
            </div>


            <div className="filter-item">
              <label htmlFor="filter-unit">Unit</label>
              <select
                id="filter-unit"
                className="form-control"
                value={unit}
                onChange={(e) => handleUnitChange(e.target.value)}
              >
                <option value="">All Units</option>
                {[1, 2, 3, 4, 5].map((u) => (
                  <option key={u} value={u}>
                    Unit {u}
                  </option>
                ))}
              </select>
            </div>

            <div className="filter-item">
              <label htmlFor="filter-type">Resource Type</label>
              <select
                id="filter-type"
                className="form-control"
                value={type}
                onChange={(e) => handleTypeChange(e.target.value)}
              >
                <option value="">All Types</option>
                <option value="Handwritten Notes">Handwritten Notes</option>
                <option value="PDF Notes">PDF Notes</option>
                <option value="Class Notes">Class Notes</option>
                <option value="Previous Year Papers">Previous Year Papers</option>
                <option value="Important Questions">Important Questions</option>
                <option value="YouTube Lectures">YouTube Lectures</option>
                <option value="Teacher Resources">Teacher Resources</option>
              </select>
            </div>

            <div className="filter-item filter-reset-item">
              <label>&nbsp;</label>
              <button
                type="button"
                className="btn btn-secondary reset-btn"
                onClick={handleResetFilters}
              >
                Reset Filters
              </button>
            </div>
          </div>
        </div>

        {/* Resources Counter & Grid */}
        <div className="results-status-bar">
          <p className="results-count-text">
            {loading
              ? 'Loading resources from backend...'
              : `Showing ${visibleResources.length} of ${resources.length} resource${resources.length === 1 ? '' : 's'}`}
          </p>
        </div>

        {loading ? (
          <div className="resources-loading-box">
            <p>Fetching resources from the Flask backend...</p>
          </div>
        ) : resources.length === 0 ? (
          <div className="no-results-box">
            <h3>{type ? `No resources found for "${type}"` : 'No study resources matched your filters'}</h3>
            <p>
              {type
                ? 'No study materials have been uploaded for this category yet. You can reset the filter to view all available resources.'
                : 'Try resetting your search query or selecting a different branch and semester.'}
            </p>
            <button
              type="button"
              className="btn btn-primary"
              onClick={handleResetFilters}
            >
              Reset Filters
            </button>
          </div>
        ) : (
          <>
            <div className="resources-grid">
              {visibleResources.map((resource) => (
                <div
                  key={resource.id}
                  className="resource-card"
                  onClick={() => onSelectResource(resource)}
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
              ))}
            </div>

            {/* Pagination / Load More */}
            {visibleCount < resources.length && (
              <div className="load-more-container">
                <button
                  type="button"
                  className="btn btn-secondary load-more-btn"
                  onClick={() => setVisibleCount((prev) => prev + 6)}
                >
                  Load More Resources ({resources.length - visibleCount} remaining)
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  )
}

export default ResourcesPage
