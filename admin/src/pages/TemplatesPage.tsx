import { useEffect, useState } from "react";
import { Trash2, RefreshCw, Plus, X, Trophy, Dumbbell, Search } from "lucide-react";
import { getAdminTemplates, deleteAdminTemplate, createAdminTemplate, getExercises, type AdminTemplate, type Exercise, type CreateTemplatePayload } from "../api/api";

const TemplatesPage = () => {
  const [templates, setTemplates] = useState<AdminTemplate[]>([]);
  const [exercisesDb, setExercisesDb] = useState<Exercise[]>([]);
  const [loading, setLoading] = useState(true);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [customName, setCustomName] = useState("");
  const [exerciseSearch, setExerciseSearch] = useState("");
  
  const [builderExercises, setBuilderExercises] = useState<{
    exerciseId: number;
    nameHu: string;
  }[]>([]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [tplData, exData] = await Promise.all([getAdminTemplates(), getExercises()]);
      setTemplates(tplData);
      setExercisesDb(exData);
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleDelete = async (id: number, name: string) => {
    if (!window.confirm(`Biztosan törlöd a hivatalos sablont: "${name}"?`)) return;
    try {
      await deleteAdminTemplate(id);
      setTemplates(templates.filter((t) => t.id !== id));
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      else alert("Hiba történt a törlés során.");
    }
  };

  const openBuilder = () => {
    setCustomName("");
    setExerciseSearch("");
    setBuilderExercises([]);
    setIsModalOpen(true);
  };

  const handleAddExerciseToBuilder = (exercise: Exercise) => {
    setBuilderExercises([...builderExercises, {
      exerciseId: exercise.id,
      nameHu: exercise.name_hu || exercise.name,
    }]);
    setExerciseSearch("");
  };

  const handleRemoveExerciseFromBuilder = (exerciseIndex: number) => {
    const newEx = [...builderExercises];
    newEx.splice(exerciseIndex, 1);
    setBuilderExercises(newEx);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (builderExercises.length === 0) {
      alert("Adj hozzá legalább egy gyakorlatot az edzéstervhez!");
      return;
    }

    const payload: CreateTemplatePayload = {
      customName,
      durationMinutes: 0,
      caloriesBurnt: 0,
      exercises: builderExercises.map(ex => ({
        exerciseId: ex.exerciseId,
        sets: [] 
      }))
    };

    try {
      await createAdminTemplate(payload);
      alert("Hivatalos sablon sikeresen létrehozva!");
      setIsModalOpen(false);
      fetchData(); 
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      else alert("Hiba történt a mentés során.");
    }
  };

  const filteredExercises = exercisesDb.filter(ex => {
    const searchLower = exerciseSearch.toLowerCase();
    const huName = ex.name_hu || "";
    const enName = ex.name || "";
    return huName.toLowerCase().includes(searchLower) || enName.toLowerCase().includes(searchLower);
  });

  return (
    <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl overflow-hidden flex flex-col relative h-[85vh]">
      <div className="p-6 border-b border-[#27272a] bg-[#121212]/50 flex justify-between items-center">
        <div>
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <Trophy className="text-yellow-400" /> Hivatalos Edzéstervek
          </h2>
          <p className="text-sm text-gray-500 mt-1">Ezeket a sablonokat minden felhasználó látni fogja.</p>
        </div>
        <div className="flex gap-3">
          <button onClick={fetchData} className="p-2 sm:px-4 sm:py-2 bg-[#27272a] hover:bg-[#3f3f46] text-gray-300 hover:text-white border border-[#3f3f46] rounded-xl transition flex items-center gap-2">
            <RefreshCw size={16} /> <span className="hidden sm:inline font-medium">Frissítés</span>
          </button>
          <button onClick={openBuilder} className="px-4 py-2 bg-yellow-400 hover:bg-yellow-300 text-black font-bold rounded-xl transition flex items-center gap-2">
            <Plus size={20} /> <span className="hidden sm:inline">Új Sablon</span>
          </button>
        </div>
      </div>

      <div className="overflow-x-auto flex-1 custom-scrollbar p-6">
        {loading ? (
          <div className="text-center text-yellow-400 animate-pulse py-12 flex items-center justify-center gap-3">
            <RefreshCw className="animate-spin" size={20} /> Betöltés...
          </div>
        ) : templates.length === 0 ? (
          <div className="text-center text-gray-500 py-12 border-2 border-dashed border-[#27272a] rounded-2xl">
            Még nincs egyetlen hivatalos sablon sem. Hozz létre egyet!
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {templates.map(tpl => (
              <div key={tpl.id} className="bg-[#121212] border border-[#27272a] rounded-2xl p-5 shadow-lg relative overflow-hidden group">
                <div className="absolute top-0 right-0 p-4 opacity-5 pointer-events-none group-hover:scale-110 transition-transform">
                  <Trophy size={100} />
                </div>
                <h3 className="text-xl font-bold text-yellow-400 mb-4 pb-4 border-b border-[#27272a]">{tpl.customName}</h3>
                
                <div className="space-y-2 mb-6">
                  <p className="text-xs font-bold text-gray-500 uppercase tracking-wider">Gyakorlatok ({tpl.exerciseCount})</p>
                  {tpl.exercises.slice(0, 4).map((ex, i) => (
                    <div key={i} className="text-sm text-gray-300 flex justify-between">
                      <span className="truncate pr-2">• {ex.nameHu}</span>
                    </div>
                  ))}
                  {tpl.exercises.length > 4 && (
                    <p className="text-xs text-gray-500 italic">+ {tpl.exercises.length - 4} további gyakorlat...</p>
                  )}
                </div>

                <button onClick={() => handleDelete(tpl.id, tpl.customName)} className="w-full py-2 bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white rounded-xl transition font-medium flex items-center justify-center gap-2">
                  <Trash2 size={16} /> Sablon Törlése
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl w-full max-w-2xl max-h-[95vh] flex flex-col">
            <div className="p-6 border-b border-[#27272a] flex justify-between items-center shrink-0">
              <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                <Trophy className="text-yellow-400" /> Hivatalos Sablon Létrehozása
              </h2>
              <button onClick={() => setIsModalOpen(false)} className="text-gray-400 hover:text-white transition">
                <X size={24} />
              </button>
            </div>

            <div className="p-6 overflow-y-auto custom-scrollbar flex-1 bg-[#0a0a0a]">
              <form id="template-form" onSubmit={handleSubmit} className="space-y-8">
                
                <div>
                  <label className="block text-sm font-medium text-gray-400 mb-2">Sablon Neve (Ezt látják a felhasználók) <span className="text-yellow-400">*</span></label>
                  <input required type="text" placeholder="pl: Kezdő Teljes Test Átmozgatás" className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-3 rounded-xl focus:border-yellow-400 outline-none text-lg font-medium" value={customName} onChange={e => setCustomName(e.target.value)} />
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  
                  <div className="bg-[#121212] border border-[#27272a] rounded-2xl p-4 flex flex-col h-[350px]">
                    <h3 className="font-bold text-white mb-3">Kereső</h3>
                    
                    <div className="relative mb-3 shrink-0">
                      <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                      <input 
                        type="text" 
                        placeholder="Gyakorlat neve..." 
                        value={exerciseSearch}
                        onChange={e => setExerciseSearch(e.target.value)}
                        className="w-full bg-[#18181b] border border-[#27272a] text-white pl-9 pr-3 py-2 text-sm rounded-lg focus:border-yellow-400 outline-none"
                      />
                    </div>

                    <div className="flex-1 overflow-y-auto custom-scrollbar space-y-1 pr-1">
                      {filteredExercises.length === 0 ? (
                        <p className="text-center text-xs text-gray-500 mt-4">Nincs találat.</p>
                      ) : (
                        filteredExercises.map(ex => (
                          <div key={ex.id} className="flex justify-between items-center p-2 rounded-lg hover:bg-[#18181b] group transition cursor-pointer" onClick={() => handleAddExerciseToBuilder(ex)}>
                            <div className="overflow-hidden pr-2">
                              <p className="text-sm text-white truncate">{ex.name_hu || ex.name}</p>
                              <p className="text-[10px] text-gray-500 truncate">{ex.category_hu || ex.category}</p>
                            </div>
                            <button type="button" className="text-gray-500 group-hover:text-yellow-400 group-hover:bg-yellow-400/10 p-1 rounded-md transition shrink-0">
                              <Plus size={16} />
                            </button>
                          </div>
                        ))
                      )}
                    </div>
                  </div>

                  <div className="bg-[#121212] border border-[#27272a] rounded-2xl p-4 flex flex-col h-[350px]">
                    <h3 className="font-bold text-white mb-3 flex items-center justify-between">
                      <span>Edzésterv tartalma</span>
                      <span className="bg-yellow-400 text-black text-xs px-2 py-0.5 rounded-full">{builderExercises.length}</span>
                    </h3>
                    
                    <div className="flex-1 overflow-y-auto custom-scrollbar space-y-2 pr-1">
                      {builderExercises.length === 0 ? (
                        <div className="h-full flex flex-col items-center justify-center text-center text-gray-500 p-4 border-2 border-dashed border-[#27272a] rounded-xl">
                          <Dumbbell size={32} className="mb-2 opacity-20" />
                          <p className="text-sm">Keresd meg a gyakorlatot a bal oldalon, és kattints rá a hozzáadáshoz!</p>
                        </div>
                      ) : (
                        builderExercises.map((ex, exIndex) => (
                          <div key={exIndex} className="bg-[#18181b] border border-[#27272a] rounded-xl p-3 flex justify-between items-center group">
                            <h4 className="font-bold text-white text-sm truncate pr-2"><span className="text-gray-500 mr-1">{exIndex + 1}.</span> {ex.nameHu}</h4>
                            <button type="button" onClick={() => handleRemoveExerciseFromBuilder(exIndex)} className="text-gray-500 hover:text-red-500 hover:bg-red-500/10 p-1.5 rounded-lg transition shrink-0">
                              <X size={16} />
                            </button>
                          </div>
                        ))
                      )}
                    </div>
                  </div>

                </div>
              </form>
            </div>

            <div className="p-6 border-t border-[#27272a] bg-[#18181b] flex justify-end gap-3 shrink-0">
              <button type="button" onClick={() => setIsModalOpen(false)} className="px-6 py-3 bg-[#27272a] hover:bg-[#3f3f46] text-white font-medium rounded-xl transition">
                Mégse
              </button>
              <button type="submit" form="template-form" className="px-6 py-3 bg-yellow-400 hover:bg-yellow-300 text-black font-extrabold rounded-xl transition shadow-[0_0_15px_rgba(250,204,21,0.3)]">
                Sablon Mentése
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TemplatesPage;