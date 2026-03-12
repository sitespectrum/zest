import { useEffect, useState } from "react";
import { Trash2, RefreshCw, Search } from "lucide-react";
import { getAdminWorkouts, deleteAdminWorkout, type AdminWorkout } from "../api/api";

const WorkoutsPage = () => {
  const [workouts, setWorkouts] = useState<AdminWorkout[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  const fetchWorkouts = async () => {
    setLoading(true);
    try {
      const data = await getAdminWorkouts();
      setWorkouts(data);
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWorkouts();
  }, []);

  const handleDelete = async (id: number, name: string) => {
    if (!window.confirm(`Biztosan törlöd ezt az edzést: "${name}"? A felhasználó is elveszíti az adatait!`)) return;
    try {
      await deleteAdminWorkout(id);
      setWorkouts(workouts.filter((w) => w.id !== id));
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      else alert("Hiba történt a törlés során.");
    }
  };

  const filteredWorkouts = workouts.filter(w => {
    const term = search.toLowerCase();
    return (
      w.userName.toLowerCase().includes(term) ||
      (w.customName || "").toLowerCase().includes(term) ||
      (w.workoutName || "").toLowerCase().includes(term)
    );
  });

  return (
    <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl overflow-hidden flex flex-col h-[85vh]">
      <div className="p-6 border-b border-[#27272a] bg-[#121212]/50 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-white">Felhasználói Edzések</h2>
          <p className="text-sm text-gray-500 mt-1">Összesen {workouts.length} rögzített edzés.</p>
        </div>
        <div className="flex w-full sm:w-auto gap-3">
          <div className="relative flex-1 sm:w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input 
              type="text" 
              placeholder="Keresés (Név / Edzés)..." 
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full bg-[#27272a] border border-[#3f3f46] text-white pl-10 pr-4 py-2 rounded-xl focus:border-[#40ff32] outline-none transition"
            />
          </div>
          <button onClick={fetchWorkouts} className="p-2 sm:px-4 sm:py-2 bg-[#27272a] hover:bg-[#3f3f46] text-gray-300 hover:text-white border border-[#3f3f46] rounded-xl transition flex items-center gap-2">
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
                <th className="p-4 pl-6 border-b border-[#27272a]">ID / Dátum</th>
                <th className="p-4 border-b border-[#27272a]">Felhasználó</th>
                <th className="p-4 border-b border-[#27272a]">Edzés Neve / Sablon</th>
                <th className="p-4 border-b border-[#27272a]">Adatok</th>
                <th className="p-4 pr-6 border-b border-[#27272a] text-right">Művelet</th>
              </tr>
            </thead>
            <tbody>
              {filteredWorkouts.map((w) => (
                <tr key={w.id} className="hover:bg-[#27272a]/50 transition border-b border-[#27272a]/50 group">
                  <td className="p-4 pl-6">
                    <p className="text-gray-500 font-mono text-sm">#{w.id}</p>
                    <p className="text-gray-400 text-xs">{new Date(w.date).toLocaleString('hu-HU', { dateStyle: 'short', timeStyle: 'short' })}</p>
                  </td>
                  <td className="p-4 font-medium text-white">
                    {w.userName} <span className="text-gray-500 text-xs">(ID: {w.userId})</span>
                  </td>
                  <td className="p-4">
                    <p className="font-bold text-[#40ff32]">{w.customName || w.workoutName}</p>
                    {w.isCustom && <span className="inline-block mt-1 px-2 py-0.5 bg-blue-500/20 text-blue-400 text-[10px] rounded uppercase font-bold tracking-wider border border-blue-500/20">Mentett Sablon</span>}
                  </td>
                  <td className="p-4">
                    <div className="flex flex-col gap-1 text-sm text-gray-300">
                      <span>⏱ {w.durationMinutes} perc</span>
                      <span>🔥 {w.totalBurntCalories} kcal</span>
                    </div>
                  </td>
                  <td className="p-4 pr-6 text-right">
                    <button onClick={() => handleDelete(w.id, w.customName || w.workoutName)} className="p-2 bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white rounded-xl transition">
                      <Trash2 size={18} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default WorkoutsPage;