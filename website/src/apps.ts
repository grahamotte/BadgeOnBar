export const apps = {
  mail: { name: "Mail", tile: "#3b82f6", glyph: "mail" },
  chat: { name: "Chat", tile: "#34c759", glyph: "chat" },
  tasks: { name: "Tasks", tile: "#ff9f0a", glyph: "tasks" },
  team: { name: "Team", tile: "#7c5cf0", glyph: "hash" },
  files: { name: "Files", tile: "#8e8e93", glyph: "folder" },
  notes: { name: "Notes", tile: "#e8b923", glyph: "note" },
} as const;

export type AppKey = keyof typeof apps;

export const badgeColors = [
  { name: "Red", value: "#ff3b30" },
  { name: "Green", value: "#34c759" },
  { name: "Blue", value: "#007aff" },
  { name: "Purple", value: "#5c1fe6" },
  { name: "Black", value: "#000000" },
  { name: "Pink", value: "#ff0080" },
] as const;
