import { useEffect, useState } from "react";
import { Trash2, RefreshCw, Search, Radio } from "lucide-react";
import { getAdminSessions, deleteAdminSession, type AdminSession } from "../api/api";

const SessionsPage = () => {
  const [sessions, setSessions] = useState<AdminSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  const fetchSessions = async () => {
    setLoading(true);
    try {
      const data = await getAdminSessions();
      setSessions(data);
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSessions();
  }, []);

  // Itt csak sessionId-t adunk át
  const handleDelete = async (sessionId: string) => {
    if (!window.confirm(`Biztosan kényszerítve leállítod és törlöd a(z) ${sessionId} sessiont? Minden résztvevő azonnal ki lesz dobva!`)) return;
    try {
      await deleteAdminSession(sessionId);
      setSessions(sessions.filter((s) => s.sessionId !== sessionId));
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      else alert("Hiba történt a törlés során.");
    }
  };

  const filteredSessions = sessions.filter(s => {
    const term = search.toLowerCase();
    return (
      s.sessionId.toLowerCase().includes(term) ||
      s.name.toLowerCase().includes(term) ||
      s.hostName.toLowerCase().includes(term)
    );
  });

  return (
    <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl overflow-hidden flex flex-col h-[85vh]">
      <div className="p-6 border-b border-[#27272a] bg-[#121212]/50 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <Radio className="text-[#40ff32]" /> Közös Edzések (Jamek)
          </h2>
          <p className="text-sm text-gray-500 mt-1">Összesen {sessions.length} aktív / korábbi szoba.</p>
        </div>
        <div className="flex w-full sm:w-auto gap-3">
          <div className="relative flex-1 sm:w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input 
              type="text" 
              placeholder="Keresés (ID / Név / Host)..." 
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full bg-[#27272a] border border-[#3f3f46] text-white pl-10 pr-4 py-2 rounded-xl focus:border-[#40ff32] outline-none transition"
            />
          </div>
          <button onClick={fetchSessions} className="p-2 sm:px-4 sm:py-2 bg-[#27272a] hover:bg-[#3f3f46] text-gray-300 hover:text-white border border-[#3f3f46] rounded-xl transition flex items-center gap-2">
            <RefreshCw size={16} />
            <span className="hidden sm:inline font-medium">Frissítés</span>
          </button>
        </div>
      </div>

      <div className="overflow-x-auto flex-1 custom-scrollbar">
        {loading ? (
          <div className="p-12 text-center text-[#40ff32] animate-pulse flex items-center justify-center gap-3">
            <RefreshCw className="animate-spin" size={20} /> Betöltés...
          </div>
        ) : (
          <table className="w-full text-left border-collapse min-w-[900px]">
            <thead className="sticky top-0 z-10 bg-[#18181b] shadow-sm">
              <tr className="text-gray-400 text-xs uppercase tracking-wider">
                <th className="p-4 pl-6 border-b border-[#27272a]">ID / Kód</th>
                <th className="p-4 border-b border-[#27272a]">Szoba Neve & Host</th>
                <th className="p-4 border-b border-[#27272a]">Státusz & Játékosok</th>
                <th className="p-4 border-b border-[#27272a]">Létrehozva</th>
                <th className="p-4 pr-6 border-b border-[#27272a] text-right">Művelet</th>
              </tr>
            </thead>
            <tbody>
              {filteredSessions.map((s) => (
                <tr key={s.sessionId} className="hover:bg-[#27272a]/50 transition border-b border-[#27272a]/50 group">
                  <td className="p-4 pl-6">
                    <p className="text-[#40ff32] font-mono font-bold tracking-widest">{s.sessionId}</p>
                  </td>
                  <td className="p-4">
                    <p className="font-bold text-white">{s.name}</p>
                    <p className="text-gray-400 text-sm flex items-center gap-1 mt-1">
                      👑 {s.hostName}
                    </p>
                  </td>
                  <td className="p-4">
                    <div className="flex flex-col gap-2 items-start">
                      {/* BEMAPPOLVA A C# ENUMOKHOZ (Lobby, In_Progress, Finished) */}
                      {s.status === "Lobby" && <span className="px-2 py-0.5 bg-yellow-500/20 text-yellow-400 text-xs rounded font-bold uppercase tracking-wider border border-yellow-500/20 animate-pulse">Lobby (Várakozás)</span>}
                      {s.status === "In_Progress" && <span className="px-2 py-0.5 bg-[#40ff32]/20 text-[#40ff32] text-xs rounded font-bold uppercase tracking-wider border border-[#40ff32]/20 shadow-[0_0_8px_rgba(64,255,50,0.3)]">Élő / Fut</span>}
                      {s.status === "Finished" && <span className="px-2 py-0.5 bg-gray-500/20 text-gray-400 text-xs rounded font-bold uppercase tracking-wider border border-gray-500/20">Befejezett</span>}
                      
                      <span className="text-sm text-gray-300">👥 {s.participantCount} résztvevő</span>
                    </div>
                  </td>
                  <td className="p-4 text-gray-400 text-sm">
                    {new Date(s.createdAt).toLocaleString('hu-HU', { dateStyle: 'short', timeStyle: 'short' })}
                  </td>
                  <td className="p-4 pr-6 text-right">
                    <button onClick={() => handleDelete(s.sessionId)} title="Kényszerített leállítás / Törlés" className="p-2 bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white rounded-xl transition">
                      <Trash2 size={18} />
                    </button>
                  </td>
                </tr>
              ))}
              {filteredSessions.length === 0 && !loading && (
                <tr>
                  <td colSpan={5} className="p-12 text-center text-gray-500">
                    Nincs a keresésnek megfelelő session.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default SessionsPage;