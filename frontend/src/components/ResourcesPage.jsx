import { useState, useEffect, useCallback } from 'react'
import { apiFetch, apiUrl } from '../api'
import { formatSubjectOption, useAcademicOptions } from '../hooks/useAcademicOptions'

function ResourcesPage({ onSelectResource, onShareClick, initialType = '', user }) {
  const [resources, setResources] = useState([])
  const [savedResourceIds, setSavedResourceIds] = useState([])
  const [savingResourceId, setSavingResourceId] = useState(null)
  const [loading, setLoading] = useState(true)
  const [resourceError, setResourceError] = useState('')
  const [visibleCount, setVisibleCount] = useState(6)

  // Filters state initialized with initialType
  const [search, setSearch] = useState('')
  const [branch, setBranch] = useState('')
  const [semester, setSemester] = useState('')
  const [subject, setSubject] = useState('')
  const [unit, setUnit] = useState('')
  const [type, setType] = useState(initialType)

  // Dynamic unit list fetched from backend for selected subject
  const [unitOptions, setUnitOptions] = useState([])
  const [unitsLoading, setUnitsLoading] = useState(false)
  const {
    branches: branchOptions,
    semesters,
    subjects: subjectOptions,
    subjectsLoading,
    error: academicError,
  } = useAcademicOptions(branch, semester)

    // Fetch saved resources for the logged-in user
  useEffect(() => {
    let ignore = false

    async function fetchSavedResources() {
      if (!user?.token) {
        setSavedResourceIds([])
        return
      }

      try {
        const res = await apiFetch('/resources/saved', {}, user.token)
        const data = await res.json()

        if (res.ok && !ignore) {
          const ids = (data.resources || []).map((resource) => resource.id)
          setSavedResourceIds(ids)
        }
      } catch (error) {
        console.error('Error fetching saved resources:', error)
      }
    }

    fetchSavedResources()

    return () => {
      ignore = true
    }
  }, [user?.token])

    const handleSaveResource = async (e, resourceId) => {
    e.stopPropagation()

    if (!user?.token) {
      alert('Please login to save resources.')
      return
    }

    setSavingResourceId(resourceId)

    const isSaved = savedResourceIds.includes(resourceId)

    try {
      const res = await apiFetch(`/resources/${resourceId}/saved`, {
        method: isSaved ? 'DELETE' : 'POST'
      }, user.token)

      const data = await res.json()

      if (!res.ok) {
        throw new Error(data.message || 'Unable to update saved resource.')
      }

      setSavedResourceIds((prev) =>
        isSaved
          ? prev.filter((id) => id !== resourceId)
          : [...prev, resourceId]
      )
    } catch (error) {
      alert(error.message || 'Something went wrong.')
    } finally {
      setSavingResourceId(null)
    }
  }

  // Fetch unit options whenever subject, branch, or semester changes
  useEffect(() => {
    let ignore = false

    async function fetchUnits() {
      if (!subject) {
        setUnitOptions([])
        return
      }

      setUnitsLoading(true)
      const params = new URLSearchParams()
      params.append('subject', subject)
      if (branch) params.append('branch', branch)
      if (semester) params.append('semester', semester)

      try {
        const res = await apiFetch(`/units?${params.toString()}`)
        if (!res.ok) throw new Error('failed')
        const data = await res.json()
        if (!ignore) {
          setUnitOptions(Array.isArray(data) ? data : [])
          setUnitsLoading(false)
        }
      } catch {
        if (!ignore) {
          setUnitOptions([])
          setUnitsLoading(false)
        }
      }
    }

    fetchUnits()
    return () => { ignore = true }
  }, [subject, branch, semester])

  const loadResources = useCallback((queryOverride = {}) => {
    setLoading(true)
    setResourceError('')
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

    apiFetch(`/resources?${params.toString()}`)
      .then(async (res) => {
        const data = await res.json()
        if (!res.ok) throw new Error(data.message || 'Unable to load resources.')
        return data
      })
      .then((data) => {
        setResources(data.resources || [])
        setLoading(false)
        setVisibleCount(6)
      })
      .catch((err) => {
        console.error('Error fetching resources:', err)
        setResourceError(err.message || 'Unable to load resources.')
        setResources([])
        setLoading(false)
      })
  }, [search, branch, semester, subject, unit, type])

  // Initial load respecting initialType
  useEffect(() => {
    let ignore = false
    const params = new URLSearchParams()
    if (initialType) params.append('type', initialType)

    setResourceError('')
    apiFetch(`/resources?${params.toString()}`)
      .then(async (res) => {
        const data = await res.json()
        if (!res.ok) throw new Error(data.message || 'Unable to load resources.')
        return data
      })
      .then((data) => {
        if (!ignore) {
          setResources(data.resources || [])
          setLoading(false)
        }
      })
      .catch((err) => {
        if (!ignore) {
          console.error('Error fetching resources:', err)
          setResourceError(err.message || 'Unable to load resources.')
          setLoading(false)
        }
      })
    return () => {
      ignore = true
    }
  }, [initialType])

  const handleBranchChange = (newBranch) => {
    setBranch(newBranch)
    setSemester('')
    setSubject('')
    setUnit('')
    loadResources({ branch: newBranch, semester: '', subject: '', unit: '' })
  }

  const handleSemesterChange = (newSemester) => {
    setSemester(newSemester)
    setSubject('')
    setUnit('')
    loadResources({ semester: newSemester, subject: '', unit: '' })
  }

  const handleSubjectChange = (newSubject) => {
    setSubject(newSubject)
    setUnit('')
    loadResources({ subject: newSubject, unit: '' })
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

  // Derive the placeholder text for the subject dropdown
  const subjectPlaceholder = subjectsLoading
    ? 'Loading subjects...'
    : academicError
      ? 'Could not load subjects'
      : !branch || !semester
        ? 'Select branch and semester first'
      : subjectOptions.length === 0
        ? 'No subjects available'
        : 'All Subjects'

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
                {branchOptions.map((option) => (
                  <option key={option.id} value={option.name}>{option.name}</option>
                ))}
              </select>
            </div>

            <div className="filter-item">
              <label htmlFor="filter-semester">Semester</label>
              <select
                id="filter-semester"
                className="form-control"
                value={semester}
                onChange={(e) => handleSemesterChange(e.target.value)}
                disabled={!branch}
              >
                <option value="">
                  {branch ? 'All Semesters' : 'Select branch first'}
                </option>
                {semesters.map((sem) => (
                  <option key={sem.id} value={sem.number}>
                    {sem.name}
                  </option>
                ))}
              </select>
            </div>

            {/* Subject dropdown — populated dynamically from GET /subjects */}
            <div className="filter-item">
              <label htmlFor="filter-subject">Subject</label>
              <select
                id="filter-subject"
                className="form-control"
                value={subject}
                onChange={(e) => handleSubjectChange(e.target.value)}
                disabled={!branch || !semester || subjectsLoading}
              >
                <option value="">{subjectPlaceholder}</option>
                {subjectOptions.map((s) => (
                  <option key={s.id} value={s.name}>{formatSubjectOption(s)}</option>
                ))}
              </select>
            </div>

            {/* Unit dropdown — populated dynamically when subject is chosen */}
            <div className="filter-item">
              <label htmlFor="filter-unit">Unit</label>
              <select
                id="filter-unit"
                className="form-control"
                value={unit}
                onChange={(e) => handleUnitChange(e.target.value)}
                disabled={unitsLoading}
              >
                <option value="">All Units</option>
                {unitOptions.length > 0 ? (
                  unitOptions.map((u) => (
                    <option key={u.id || u.unit_number} value={u.unit_number}>
                      Unit {u.unit_number}{u.name ? `: ${u.name}` : ''}
                    </option>
                  ))
                ) : null}
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
                <option value="Previous Year Question Papers">Previous Year Question Papers</option>
                <option value="Important Questions">Important Questions</option>
                <option value="YouTube Resources">YouTube Resources</option>
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

        {resourceError ? (
          <div className="no-results-box" role="alert">
            <h3>Resources could not be loaded</h3>
            <p>{resourceError}</p>
            <button type="button" className="btn btn-primary" onClick={() => loadResources()}>
              Try Again
            </button>
          </div>
        ) : loading ? (
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
                    {resource.subject_code ? `${resource.subject_code} - ` : ''}
                    {resource.subject} · {resource.unit_label || `Unit ${resource.unit}`}
                  </p>
                  <p className="resource-description">{resource.type}</p>

                  <div style={{ marginTop: '0.85rem', display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                    <button
                      type="button"
                      className="btn btn-outline"
                      disabled={savingResourceId === resource.id}
                      onClick={(e) => handleSaveResource(e, resource.id)}
                      style={{ fontSize: '0.82rem', padding: '0.35rem 0.75rem' }}
                    >
                      {savingResourceId === resource.id
                        ? 'Please wait...'
                        : savedResourceIds.includes(resource.id)
                          ? '♥ Saved'
                          : '♡ Save'}
                    </button>
                    {resource.filename && (
                      <>
                        <a
                          href={apiUrl(`/uploads/${resource.filename}`)}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="btn btn-secondary"
                          style={{ fontSize: '0.82rem', padding: '0.35rem 0.75rem', textDecoration: 'none' }}
                          onClick={(e) => e.stopPropagation()}
                        >
                          View File
                        </a>
                        <a
                          href={apiUrl(`/download/${resource.filename}`)}
                          download
                          className="btn btn-outline"
                          style={{ fontSize: '0.82rem', padding: '0.35rem 0.75rem', textDecoration: 'none' }}
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
                        style={{ fontSize: '0.82rem', padding: '0.35rem 0.75rem', textDecoration: 'none' }}
                        onClick={(e) => e.stopPropagation()}
                      >
                        Open Resource &rarr;
                      </a>
                    )}
                  </div>
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
