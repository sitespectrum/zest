import { useEffect, useState } from "react";
import { Trash2, RefreshCw, Search } from "lucide-react";
import { getAdminMeals, deleteAdminMeal, type AdminMeal } from "../api/api";

const MealsPage = () => {
  const [meals, setMeals] = useState<AdminMeal[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  const fetchMeals = async () => {
    setLoading(true);
    try {
      const data = await getAdminMeals();
      setMeals(data);
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMeals();
  }, []);

  const handleDelete = async (id: number, name: string) => {
    if (!window.confirm(`Biztosan törlöd ezt az étkezést: "${name}"? A felhasználó is elveszíti az adatait!`)) return;
    try {
      await deleteAdminMeal(id);
      setMeals(meals.filter((m) => m.id !== id));
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      else alert("Hiba történt a törlés során.");
    }
  };

  const filteredMeals = meals.filter(m => {
    const term = search.toLowerCase();
    return (
      m.userName.toLowerCase().includes(term) ||
      (m.customName || "").toLowerCase().includes(term) ||
      (m.mealName || "").toLowerCase().includes(term)
    );
  });

  return (
    <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl overflow-hidden flex flex-col h-[85vh]">
      <div className="p-6 border-b border-[#27272a] bg-[#121212]/50 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-white">Felhasználói Étkezések</h2>
          <p className="text-sm text-gray-500 mt-1">Összesen {meals.length} rögzített étkezés.</p>
        </div>
        <div className="flex w-full sm:w-auto gap-3">
          <div className="relative flex-1 sm:w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input 
              type="text" 
              placeholder="Keresés (Név / Étkezés)..." 
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full bg-[#27272a] border border-[#3f3f46] text-white pl-10 pr-4 py-2 rounded-xl focus:border-[#40ff32] outline-none transition"
            />
          </div>
          <button onClick={fetchMeals} className="p-2 sm:px-4 sm:py-2 bg-[#27272a] hover:bg-[#3f3f46] text-gray-300 hover:text-white border border-[#3f3f46] rounded-xl transition flex items-center gap-2">
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
                <th className="p-4 border-b border-[#27272a]">Étkezés Neve / Sablon</th>
                <th className="p-4 border-b border-[#27272a]">Kalória</th>
                <th className="p-4 pr-6 border-b border-[#27272a] text-right">Művelet</th>
              </tr>
            </thead>
            <tbody>
              {filteredMeals.map((m) => (
                <tr key={m.id} className="hover:bg-[#27272a]/50 transition border-b border-[#27272a]/50 group">
                  <td className="p-4 pl-6">
                    <p className="text-gray-500 font-mono text-sm">#{m.id}</p>
                    <p className="text-gray-400 text-xs">{new Date(m.eatenAt).toLocaleString('hu-HU', { dateStyle: 'short', timeStyle: 'short' })}</p>
                  </td>
                  <td className="p-4 font-medium text-white">
                    {m.userName} <span className="text-gray-500 text-xs">(ID: {m.userId})</span>
                  </td>
                  <td className="p-4">
                    <p className="font-bold text-[#40ff32]">{m.customName || m.mealName}</p>
                    {m.isCustom && <span className="inline-block mt-1 px-2 py-0.5 bg-orange-500/20 text-orange-400 text-[10px] rounded uppercase font-bold tracking-wider border border-orange-500/20">Mentett Sablon</span>}
                  </td>
                  <td className="p-4">
                    <span className="text-white font-medium">🔥 {m.totalCalories.toFixed(0)} kcal</span>
                  </td>
                  <td className="p-4 pr-6 text-right">
                    <button onClick={() => handleDelete(m.id, m.customName || m.mealName)} className="p-2 bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white rounded-xl transition">
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

export default MealsPage;