import { useEffect, useState } from "react";
import { Trash2, RefreshCw, Plus, X, Trophy, Dumbbell } from "lucide-react";
import { getAdminTemplates, deleteAdminTemplate, createAdminTemplate, getExercises, type AdminTemplate, type Exercise, type CreateTemplatePayload } from "../api/api";

const TemplatesPage = () => {
  const [templates, setTemplates] = useState<AdminTemplate[]>([]);
  const [exercisesDb, setExercisesDb] = useState<Exercise[]>([]);
  const [loading, setLoading] = useState(true);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [customName, setCustomName] = useState("");
  const [duration, setDuration] = useState(60);
  const [calories, setCalories] = useState(300);
  
  const [builderExercises, setBuilderExercises] = useState<{
    exerciseId: number;
    nameHu: string;
    sets: { weight: number; reps: number }[];
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
    setDuration(60);
    setCalories(300);
    setBuilderExercises([]);
    setIsModalOpen(true);
  };

  const handleAddExerciseToBuilder = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const exId = parseInt(e.target.value);
    if (!exId) return;
    
    const exercise = exercisesDb.find(ex => ex.id === exId);
    if (exercise) {
      setBuilderExercises([...builderExercises, {
        exerciseId: exercise.id,
        nameHu: exercise.name_hu || exercise.name,
        sets: [{ weight: 0, reps: 10 }]
      }]);
    }
    e.target.value = "";
  };

  const handleAddSet = (exerciseIndex: number) => {
    const newEx = [...builderExercises];
    newEx[exerciseIndex].sets.push({ weight: 0, reps: 10 });
    setBuilderExercises(newEx);
  };

  const handleRemoveSet = (exerciseIndex: number, setIndex: number) => {
    const newEx = [...builderExercises];
    newEx[exerciseIndex].sets.splice(setIndex, 1);
    setBuilderExercises(newEx);
  };

  const handleUpdateSet = (exerciseIndex: number, setIndex: number, field: 'weight'|'reps', value: number) => {
    const newEx = [...builderExercises];
    newEx[exerciseIndex].sets[setIndex][field] = value;
    setBuilderExercises(newEx);
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
      durationMinutes: duration,
      caloriesBurnt: calories,
      exercises: builderExercises.map(ex => ({
        exerciseId: ex.exerciseId,
        sets: ex.sets
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

  return (
    <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl overflow-hidden flex flex-col relative h-[85vh]">
      <div className="p-6 border-b border-[#27272a] bg-[#121212]/50 flex justify-between items-center">
        <div>
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <Trophy className="text-yellow-400" /> Hivatalos Zest Edzéstervek
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
                <h3 className="text-xl font-bold text-yellow-400 mb-1">{tpl.customName}</h3>
                <div className="flex gap-4 text-xs text-gray-400 mb-4 pb-4 border-b border-[#27272a]">
                  <span>⏱ {tpl.durationMinutes} perc</span>
                  <span>🔥 {tpl.totalBurntCalories} kcal</span>
                </div>
                
                <div className="space-y-2 mb-6">
                  <p className="text-xs font-bold text-gray-500 uppercase tracking-wider">Gyakorlatok ({tpl.exerciseCount})</p>
                  {tpl.exercises.slice(0, 3).map((ex, i) => (
                    <div key={i} className="text-sm text-gray-300 flex justify-between">
                      <span className="truncate pr-2">• {ex.nameHu}</span>
                      <span className="text-gray-500 text-xs shrink-0">{ex.setsCount} szett</span>
                    </div>
                  ))}
                  {tpl.exercises.length > 3 && (
                    <p className="text-xs text-gray-500 italic">+ {tpl.exercises.length - 3} további gyakorlat...</p>
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
          <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl w-full max-w-4xl max-h-[95vh] flex flex-col">
            <div className="p-6 border-b border-[#27272a] flex justify-between items-center shrink-0">
              <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                <Trophy className="text-yellow-400" /> Új Hivatalos Sablon Építő
              </h2>
              <button onClick={() => setIsModalOpen(false)} className="text-gray-400 hover:text-white transition">
                <X size={24} />
              </button>
            </div>

            <div className="p-6 overflow-y-auto custom-scrollbar flex-1 bg-[#0a0a0a]">
              <form id="template-form" onSubmit={handleSubmit} className="space-y-6">
                
                <div className="bg-[#18181b] border border-[#27272a] p-5 rounded-2xl grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div className="sm:col-span-3">
                    <label className="block text-sm font-medium text-gray-400 mb-1">Sablon Neve (Látható a usereknek) <span className="text-yellow-400">*</span></label>
                    <input required type="text" placeholder="pl: Kezdő Teljes Test Átmozgatás" className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-yellow-400 outline-none" value={customName} onChange={e => setCustomName(e.target.value)} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Becsült Idő (perc)</label>
                    <input required type="number" className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-yellow-400 outline-none" value={duration} onChange={e => setDuration(parseInt(e.target.value)||0)} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Elégetett Kalória</label>
                    <input required type="number" className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-yellow-400 outline-none" value={calories} onChange={e => setCalories(parseInt(e.target.value)||0)} />
                  </div>
                </div>

                <div>
                  <h3 className="text-lg font-bold text-white mb-3 flex items-center gap-2">
                    <Dumbbell className="text-gray-400" size={18} /> Gyakorlatok ({builderExercises.length})
                  </h3>
                  
                  <select 
                    className="w-full bg-[#27272a] border border-[#3f3f46] text-white px-4 py-3 rounded-xl focus:border-yellow-400 outline-none mb-6 cursor-pointer"
                    onChange={handleAddExerciseToBuilder}
                    defaultValue=""
                  >
                    <option value="" disabled>+ Válassz egy gyakorlatot a listából a hozzáadáshoz...</option>
                    {exercisesDb.sort((a,b) => (a.name_hu || a.name).localeCompare(b.name_hu || b.name)).map(ex => (
                      <option key={ex.id} value={ex.id}>{ex.name_hu || ex.name} ({ex.category_hu || ex.category})</option>
                    ))}
                  </select>

                  <div className="space-y-4">
                    {builderExercises.map((ex, exIndex) => (
                      <div key={exIndex} className="bg-[#18181b] border border-[#27272a] rounded-2xl p-5 relative">
                        <button type="button" onClick={() => handleRemoveExerciseFromBuilder(exIndex)} className="absolute top-4 right-4 text-red-500 hover:bg-red-500/10 p-1.5 rounded-lg transition">
                          <X size={20} />
                        </button>
                        <h4 className="font-bold text-white text-lg pr-10 mb-4">{exIndex + 1}. {ex.nameHu}</h4>
                        
                        <div className="space-y-2">
                          {ex.sets.map((set, setIndex) => (
                            <div key={setIndex} className="flex items-center gap-3 bg-[#121212] p-2 rounded-xl border border-[#27272a]">
                              <span className="w-8 text-center text-gray-500 font-bold text-sm">{setIndex + 1}.</span>
                              <div className="flex-1 flex items-center bg-[#18181b] rounded-lg px-3 py-1.5 border border-[#3f3f46]">
                                <input type="number" className="w-12 bg-transparent text-white text-center outline-none" value={set.weight} onChange={e => handleUpdateSet(exIndex, setIndex, 'weight', parseFloat(e.target.value)||0)} />
                                <span className="text-gray-500 text-sm ml-1">kg</span>
                              </div>
                              <span className="text-gray-600">×</span>
                              <div className="flex-1 flex items-center bg-[#18181b] rounded-lg px-3 py-1.5 border border-[#3f3f46]">
                                <input type="number" className="w-12 bg-transparent text-white text-center outline-none" value={set.reps} onChange={e => handleUpdateSet(exIndex, setIndex, 'reps', parseInt(e.target.value)||0)} />
                                <span className="text-gray-500 text-sm ml-1">ism</span>
                              </div>
                              <button type="button" onClick={() => handleRemoveSet(exIndex, setIndex)} className="text-gray-500 hover:text-red-500 p-2 transition">
                                <Trash2 size={16} />
                              </button>
                            </div>
                          ))}
                        </div>
                        
                        <button type="button" onClick={() => handleAddSet(exIndex)} className="mt-4 text-sm text-yellow-400 hover:text-yellow-300 font-bold flex items-center gap-1 transition">
                          <Plus size={16} /> Új Szett
                        </button>
                      </div>
                    ))}
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