import { useEffect, useState } from "react";
import { Trash2, RefreshCw, Edit2, Plus, X } from "lucide-react";
import { getExercises, deleteExercise, createExercise, updateExercise, type Exercise } from "../api/api";

const emptyExercise: Omit<Exercise, "id"> = {
  name: "", name_hu: "",
  category: "", category_hu: "",
  equipment: "", equipment_hu: "",
  force: "", force_hu: "",
  level: "", level_hu: "",
  mechanic: "", mechanic_hu: "",
  metValue: 3.5,
  primaryMuscles: [], primaryMuscles_hu: [],
  secondaryMuscles: [], secondaryMuscles_hu: [],
  instructions: [], instructions_hu: [],
  images: [],
};

const ExercisesPage = () => {
  const [exercises, setExercises] = useState<Exercise[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [search, setSearch] = useState("");

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingExercise, setEditingExercise] = useState<Exercise | Omit<Exercise, "id">>(emptyExercise);

  const fetchExercises = async () => {
    setLoading(true);
    try {
      const data = await getExercises();
      setExercises(data);
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchExercises();
  }, []);

  const handleDelete = async (id: number, name: string) => {
    if (!window.confirm(`Biztosan törlöd a(z) "${name}" gyakorlatot? Ez minden user edzéséből eltávolítja!`)) return;
    try {
      await deleteExercise(id);
      setExercises(exercises.filter((e) => e.id !== id));
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      else alert("Hiba történt a törlés során.");
    }
  };

  const openModal = (exercise?: Exercise) => {
    if (exercise) setEditingExercise({ ...exercise });
    else setEditingExercise({ ...emptyExercise });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if ("id" in editingExercise) {
        await updateExercise(editingExercise.id, editingExercise as Exercise);
        setExercises(exercises.map(ex => ex.id === editingExercise.id ? (editingExercise as Exercise) : ex));
      } else {
        const created = await createExercise(editingExercise);
        setExercises([...exercises, created]);
      }
      setIsModalOpen(false);
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      else alert("Hiba történt a mentés során.");
    }
  };

  const filteredExercises = exercises.filter(ex => {
    const huName = ex.name_hu || "";
    const enName = ex.name || "";
    const searchLower = search.toLowerCase();

    return huName.toLowerCase().includes(searchLower) || 
           enName.toLowerCase().includes(searchLower);
  });

  return (
    <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl overflow-hidden flex flex-col relative h-[85vh]">
      <div className="p-6 border-b border-[#27272a] bg-[#121212]/50 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-white">Gyakorlat Könyvtár</h2>
          <p className="text-sm text-gray-500 mt-1">Összesen {exercises.length} gyakorlat az adatbázisban.</p>
        </div>
        <div className="flex w-full sm:w-auto gap-3">
          <input 
            type="text" 
            placeholder="Keresés..." 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="flex-1 sm:w-48 bg-[#27272a] border border-[#3f3f46] text-white px-4 py-2 rounded-xl focus:border-[#40ff32] outline-none"
          />
          <button onClick={() => openModal()} className="px-4 py-2 bg-[#40ff32] hover:bg-[#3ce62e] text-black font-bold rounded-xl transition flex items-center gap-2">
            <Plus size={20} /> <span className="hidden sm:inline">Új Gyakorlat</span>
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
                <th className="p-4 pl-6 border-b border-[#27272a] font-semibold">Kép</th>
                <th className="p-4 border-b border-[#27272a] font-semibold">Név (HU / EN)</th>
                <th className="p-4 border-b border-[#27272a] font-semibold">Kategória & Eszköz</th>
                <th className="p-4 pr-6 border-b border-[#27272a] text-right font-semibold">Műveletek</th>
              </tr>
            </thead>
            <tbody>
              {filteredExercises.map((ex) => (
                <tr key={ex.id} className="hover:bg-[#27272a]/50 transition border-b border-[#27272a]/50 group">
                  <td className="p-4 pl-6">
                    <div className="w-12 h-12 rounded-lg bg-[#27272a] border border-[#3f3f46] overflow-hidden flex items-center justify-center">
                      {ex.images && ex.images.length > 0 ? (
                        <img src={`https://raw.githubusercontent.com/sitespectrum/zest_exercises/main/exercises/${ex.images[0]}`} alt="img" className="w-full h-full object-cover" />
                      ) : (
                        <span className="text-gray-500 font-bold">N/A</span>
                      )}
                    </div>
                  </td>
                  <td className="p-4">
                    <p className="font-bold text-[#40ff32] text-base">{ex.name_hu || "Nincs HU név"}</p>
                    <p className="text-gray-400 text-sm">{ex.name}</p>
                  </td>
                  <td className="p-4">
                    <div className="flex flex-col gap-1">
                      <span className="text-white text-sm">{ex.category_hu || ex.category}</span>
                      <span className="text-gray-500 text-xs">{ex.equipment_hu || ex.equipment}</span>
                    </div>
                  </td>
                  <td className="p-4 pr-6 text-right">
                    <div className="flex justify-end gap-2">
                      <button onClick={() => openModal(ex)} className="p-2 bg-blue-500/10 text-blue-400 hover:bg-blue-500 hover:text-white rounded-xl transition">
                        <Edit2 size={18} />
                      </button>
                      <button onClick={() => handleDelete(ex.id, ex.name_hu || ex.name)} className="p-2 bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white rounded-xl transition">
                        <Trash2 size={18} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] flex flex-col">
            <div className="p-6 border-b border-[#27272a] flex justify-between items-center shrink-0">
              <h2 className="text-2xl font-bold text-white">
                {"id" in editingExercise ? `Szerkesztés: ${editingExercise.name_hu || editingExercise.name}` : "Új Gyakorlat Létrehozása"}
              </h2>
              <button onClick={() => setIsModalOpen(false)} className="text-gray-400 hover:text-white transition">
                <X size={24} />
              </button>
            </div>

            <div className="p-6 overflow-y-auto custom-scrollbar">
              <form id="exercise-form" onSubmit={handleSubmit} className="space-y-6">
                
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Magyar Név <span className="text-red-500">*</span></label>
                    <input required type="text" className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-[#40ff32] outline-none" value={editingExercise.name_hu} onChange={e => setEditingExercise({...editingExercise, name_hu: e.target.value})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Angol Név <span className="text-red-500">*</span></label>
                    <input required type="text" className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-[#40ff32] outline-none" value={editingExercise.name} onChange={e => setEditingExercise({...editingExercise, name: e.target.value})} />
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Kategória (HU)</label>
                    <input type="text" className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl outline-none" value={editingExercise.category_hu || ''} onChange={e => setEditingExercise({...editingExercise, category_hu: e.target.value})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Kategória (EN)</label>
                    <input type="text" className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl outline-none" value={editingExercise.category || ''} onChange={e => setEditingExercise({...editingExercise, category: e.target.value})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Eszköz (HU)</label>
                    <input type="text" className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl outline-none" value={editingExercise.equipment_hu || ''} onChange={e => setEditingExercise({...editingExercise, equipment_hu: e.target.value})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">MET Érték</label>
                    <input type="number" step="0.1" className="w-full bg-[#121212] border border-[#27272a] text-[#40ff32] font-bold px-4 py-2.5 rounded-xl outline-none" value={editingExercise.metValue} onChange={e => setEditingExercise({...editingExercise, metValue: parseFloat(e.target.value) || 0})} />
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Fő Izomcsoportok (HU, vesszővel)</label>
                    <input type="text" className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl outline-none" value={(editingExercise.primaryMuscles_hu || []).join(", ")} onChange={e => setEditingExercise({...editingExercise, primaryMuscles_hu: e.target.value.split(",").map(s => s.trim())})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Másodlagos Izomcsoportok (HU, vesszővel)</label>
                    <input type="text" className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl outline-none" value={(editingExercise.secondaryMuscles_hu || []).join(", ")} onChange={e => setEditingExercise({...editingExercise, secondaryMuscles_hu: e.target.value.split(",").map(s => s.trim())})} />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-400 mb-1">Kép fájlnevek (vesszővel elválasztva)</label>
                  <p className="text-xs text-gray-600 mb-2">Pl: Barbell_Bench_Press_1.jpg, Barbell_Bench_Press_2.jpg</p>
                  <input type="text" className="w-full bg-[#121212] border border-[#27272a] text-blue-400 px-4 py-2.5 rounded-xl outline-none font-mono text-sm" value={(editingExercise.images || []).join(", ")} onChange={e => setEditingExercise({...editingExercise, images: e.target.value.split(",").map(s => s.trim())})} />
                </div>

              </form>
            </div>

            <div className="p-6 border-t border-[#27272a] bg-[#18181b] flex justify-end gap-3 shrink-0">
              <button type="button" onClick={() => setIsModalOpen(false)} className="px-6 py-3 bg-[#27272a] hover:bg-[#3f3f46] text-white font-medium rounded-xl transition">
                Mégse
              </button>
              <button type="submit" form="exercise-form" className="px-6 py-3 bg-[#40ff32] hover:bg-[#3ce62e] text-black font-bold rounded-xl transition">
                Mentés
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ExercisesPage;