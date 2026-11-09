import { useEffect, useState } from 'react'
import { apiFetch } from '../api'

export function formatSubjectOption(subject) {
  return subject.name
}

export function useAcademicOptions(branch, semester) {
  const [branches, setBranches] = useState([])
  const [semesters, setSemesters] = useState([])
  const [subjects, setSubjects] = useState([])
  const [branchesLoading, setBranchesLoading] = useState(true)
  const [semestersLoading, setSemestersLoading] = useState(false)
  const [subjectsLoading, setSubjectsLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true
    apiFetch('/branches')
      .then(async (response) => {
        const data = await response.json()
        if (!response.ok) throw new Error(data.message || 'Unable to load branches.')
        if (active) setBranches(Array.isArray(data.branches) ? data.branches : [])
      })
      .catch((loadError) => {
        if (active) {
          setBranches([])
          setError(loadError.message || 'Unable to load branches.')
        }
      })
      .finally(() => {
        if (active) setBranchesLoading(false)
      })

    return () => { active = false }
  }, [])

  useEffect(() => {
    let active = true
    setSemesters([])
    setSubjects([])
    if (!branch) {
      setSemestersLoading(false)
      setSubjectsLoading(false)
      return () => { active = false }
    }

    setSemestersLoading(true)
    setError('')
    const params = new URLSearchParams({ branch })
    apiFetch(`/semesters?${params.toString()}`)
      .then(async (response) => {
        const data = await response.json()
        if (!response.ok) throw new Error(data.message || 'Unable to load semesters.')
        if (active) setSemesters(Array.isArray(data.semesters) ? data.semesters : [])
      })
      .catch((loadError) => {
        if (active) {
          setSemesters([])
          setError(loadError.message || 'Unable to load semesters.')
        }
      })
      .finally(() => {
        if (active) setSemestersLoading(false)
      })

    return () => { active = false }
  }, [branch])

  useEffect(() => {
    let active = true
    setSubjects([])
    if (!branch || !semester) {
      setSubjectsLoading(false)
      return () => { active = false }
    }

    setSubjectsLoading(true)
    setError('')
    const params = new URLSearchParams({ branch, semester })
    apiFetch(`/subjects?${params.toString()}`)
      .then(async (response) => {
        const data = await response.json()
        if (!response.ok) throw new Error(data.message || 'Unable to load subjects.')
        if (active) {
          setSubjects(Array.isArray(data)
            ? data.filter((subject) => subject.is_selectable !== false && subject.is_selectable !== 0)
            : [])
        }
      })
      .catch((loadError) => {
        if (active) {
          setSubjects([])
          setError(loadError.message || 'Unable to load subjects.')
        }
      })
      .finally(() => {
        if (active) setSubjectsLoading(false)
      })

    return () => { active = false }
  }, [branch, semester])

  return {
    branches,
    semesters,
    subjects,
    branchesLoading,
    semestersLoading,
    subjectsLoading,
    error,
  }
}
