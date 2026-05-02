import { defineStore } from 'pinia'

export interface Folder {
  id: number
  parent: number | null
  title: string
  outline?: string
}

export interface FolderTreeNode extends Folder {
  children: FolderTreeNode[]
}

export const useBookStore = defineStore('bookstore', {
  state: () => ({
    folders: [] as Folder[],
    // Map from folderId to HTML content string
    folderContents: new Map<number, string>(),
    // Map from folderId to outline text (lazy-loaded)
    folderOutlines: new Map<number, string>(),
    currentFolderId: null as number | null,
    // The br ID that marks where focus is (text after this br is the "current" block)
    currentBrId: null as string | null,
    focusMode: false,
    loaded: false,
    fontFamily: 'font-typewriter' as string,
    // Counter for generating unique br IDs
    brCounter: 0,
  }),

  getters: {
    folderTree(state): FolderTreeNode[] {
      const map = new Map<number, FolderTreeNode>()
      for (const f of state.folders) {
        map.set(f.id, { ...f, children: [] })
      }
      const roots: FolderTreeNode[] = []
      for (const node of map.values()) {
        if (node.parent && map.has(node.parent)) {
          map.get(node.parent)!.children.push(node)
        } else {
          roots.push(node)
        }
      }
      return roots
    },

    currentContent(state): string {
      if (state.currentFolderId === null) return ''
      return state.folderContents.get(state.currentFolderId) ?? ''
    },
  },

  actions: {
    async loadAll() {
      const folders = await $fetch<Folder[]>('/api/folders')
      this.folders = folders

      // Load content for all folders
      const contentPromises = folders.map(async (f) => {
        const data = await $fetch<{ content: string }>(`/api/texts/${f.id}`)
        return { folderId: f.id, content: data.content }
      })
      const results = await Promise.all(contentPromises)
      for (const r of results) {
        this.folderContents.set(r.folderId, r.content)
      }

      // Find the highest br counter from existing content
      let maxBr = 0
      for (const html of this.folderContents.values()) {
        const matches = html.matchAll(/id="br-(\d+)"/g)
        for (const m of matches) {
          maxBr = Math.max(maxBr, Number(m[1]))
        }
      }
      this.brCounter = maxBr

      this.loaded = true
    },

    // Folder actions
    async createFolder(title: string, parent: number | null = null) {
      const folder = await $fetch<Folder>('/api/folders', {
        method: 'POST',
        body: { title, parent },
      })
      this.folders.push(folder)
      this.folderContents.set(folder.id, '')
      return folder
    },

    async updateFolder(id: number, data: { title?: string; parent?: number | null }) {
      const folder = await $fetch<Folder>(`/api/folders/${id}`, {
        method: 'PUT',
        body: data,
      })
      const idx = this.folders.findIndex((f) => f.id === id)
      if (idx !== -1) this.folders[idx] = folder
      return folder
    },

    async deleteFolder(id: number) {
      await $fetch(`/api/folders/${id}`, { method: 'DELETE' })
      this.folders = this.folders.filter((f) => f.id !== id)
      this.folderContents.delete(id)
      const removeChildren = (parentId: number) => {
        const children = this.folders.filter((f) => f.parent === parentId)
        for (const child of children) {
          removeChildren(child.id)
          this.folders = this.folders.filter((f) => f.id !== child.id)
          this.folderContents.delete(child.id)
        }
      }
      removeChildren(id)
      if (this.currentFolderId === id) this.currentFolderId = null
    },

    // Content actions
    nextBrId(): string {
      this.brCounter++
      return `br-${this.brCounter}`
    },

    setContent(folderId: number, html: string) {
      this.folderContents.set(folderId, html)
    },

    async saveContent(folderId: number) {
      const content = this.folderContents.get(folderId) ?? ''
      await $fetch(`/api/texts/${folderId}`, {
        method: 'PUT',
        body: { content },
      })
    },

    async loadOutline(id: number): Promise<string> {
      if (this.folderOutlines.has(id)) return this.folderOutlines.get(id)!
      const data = await $fetch<{ outline: string }>(`/api/folders/${id}/outline`)
      this.folderOutlines.set(id, data.outline)
      return data.outline
    },

    async saveOutline(id: number, outline: string) {
      await $fetch(`/api/folders/${id}/outline`, { method: 'PUT', body: { outline } })
      this.folderOutlines.set(id, outline)
    },

    toggleFocusMode() {
      this.focusMode = !this.focusMode
    },

    openFolder(id: number | null) {
      this.currentFolderId = id
      this.currentBrId = null
    },
  },
})
