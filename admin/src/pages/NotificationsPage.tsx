import { useState } from "react";
import { Bell, Send, Smartphone } from "lucide-react";
import { sendGlobalNotification } from "../api/api";

const NotificationsPage = () => {
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!title.trim() || !message.trim()) {
      alert("A cím és az üzenet megadása kötelező!");
      return;
    }

    if (!window.confirm(`VIGYÁZAT! Ezt az üzenetet MINDEN Zest felhasználó megkapja a telefonjára.\n\nCím: ${title}\nÜzenet: ${message}\n\nBiztosan kiküldöd?`)) {
      return;
    }

    setLoading(true);
    try {
      await sendGlobalNotification(title, message);
      alert("🚀 Értesítés sikeresen kiküldve minden felhasználónak!");
      setTitle("");
      setMessage("");
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      else alert(error.message || "Hiba történt a küldés során.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col lg:flex-row gap-6 h-[85vh]">
      
      {/* Bal oldal: Űrlap */}
      <div className="bg-[#18181b] border border-[#27272a] rounded-3xl p-6 sm:p-8 shadow-2xl flex-1 flex flex-col relative overflow-hidden">
        <div className="absolute top-0 right-0 p-8 opacity-5 pointer-events-none">
          <Bell size={150} />
        </div>

        <div className="mb-8">
          <h2 className="text-2xl font-bold text-white flex items-center gap-2">
            <Bell className="text-[#40ff32]" /> Globális Push Értesítés
          </h2>
          <p className="text-gray-400 mt-2">
            Küldj valós idejű értesítést az összes regisztrált felhasználó mobiltelefonjára. Használd okosan, kerüld a spamelést!
          </p>
        </div>

        <form onSubmit={handleSend} className="space-y-6 flex-1 flex flex-col">
          <div>
            <label className="block text-sm font-medium text-gray-400 mb-2">Értesítés Címe (Rövid, figyelemfelkeltő)</label>
            <input 
              type="text" 
              placeholder="pl: Új Zest Frissítés Elérhető! 🎉" 
              maxLength={50}
              required
              className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-3 rounded-xl focus:border-[#40ff32] outline-none transition"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
            />
            <p className="text-xs text-gray-500 mt-1 text-right">{title.length} / 50</p>
          </div>

          <div className="flex-1 flex flex-col">
            <label className="block text-sm font-medium text-gray-400 mb-2">Értesítés Szövege</label>
            <textarea 
              placeholder="pl: Próbáld ki az új közös edzés funkciót a barátaiddal..." 
              required
              maxLength={150}
              className="w-full flex-1 bg-[#121212] border border-[#27272a] text-white px-4 py-3 rounded-xl focus:border-[#40ff32] outline-none transition resize-none custom-scrollbar min-h-[150px]"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
            />
            <p className="text-xs text-gray-500 mt-1 text-right">{message.length} / 150</p>
          </div>

          <button 
            type="submit" 
            disabled={loading || !title || !message}
            className="w-full px-6 py-4 bg-[#40ff32] hover:bg-[#3ce62e] disabled:bg-gray-600 disabled:text-gray-400 text-black font-extrabold rounded-xl transition flex items-center justify-center gap-2 text-lg shadow-[0_0_15px_rgba(64,255,50,0.3)] disabled:shadow-none"
          >
            {loading ? (
              "Küldés folyamatban..."
            ) : (
              <><Send size={22} /> Értesítés Kiküldése</>
            )}
          </button>
        </form>
      </div>

      {/* Jobb oldal: Élő Előnézet (Telefon Mockup) */}
      <div className="bg-[#121212] border border-[#27272a] rounded-3xl p-6 shadow-2xl w-full lg:w-[400px] flex flex-col items-center justify-center shrink-0">
        <h3 className="text-gray-400 font-medium mb-6 flex items-center gap-2">
          <Smartphone size={18} /> Élő Előnézet
        </h3>

        {/* Virtuális Telefon */}
        <div className="w-[300px] h-[600px] bg-black border-[8px] border-[#27272a] rounded-[40px] relative overflow-hidden shadow-2xl flex flex-col">
          {/* Notch / Dynamic Island */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-[#27272a] rounded-b-2xl z-10"></div>
          
          {/* Háttérkép / Lock Screen imitáció */}
          <div className="absolute inset-0 bg-gradient-to-b from-[#18181b] to-black opacity-50"></div>
          
          {/* Óra */}
          <div className="relative z-10 text-center mt-12 mb-8">
            <h1 className="text-5xl font-extrabold text-white/90">09:41</h1>
            <p className="text-white/60 text-sm mt-1">Szerda, Október 12</p>
          </div>

          {/* Maga a Push Értesítés kártya */}
          <div className="relative z-10 px-3 transition-all duration-300">
            <div className={`bg-[#1e1e1e]/80 backdrop-blur-md border border-[#3f3f46]/50 rounded-2xl p-4 shadow-lg transition-all ${title || message ? 'opacity-100 translate-y-0' : 'opacity-0 -translate-y-4'}`}>
              <div className="flex items-center gap-2 mb-2">
                <div className="w-5 h-5 rounded-md bg-[#40ff32] flex items-center justify-center p-0.5">
                  <img src="/Zest_logo.png" alt="icon" className="w-full h-full object-contain brightness-0" />
                </div>
                <span className="text-xs text-gray-300 uppercase tracking-wider font-semibold">Zest</span>
                <span className="text-xs text-gray-500 ml-auto">Most</span>
              </div>
              <h4 className="text-white font-bold text-sm leading-tight mb-1 truncate">{title || "Értesítés Címe"}</h4>
              <p className="text-gray-300 text-xs leading-snug line-clamp-3 break-words">
                {message || "Az értesítés szövege itt fog megjelenni..."}
              </p>
            </div>
          </div>
        </div>
      </div>

    </div>
  );
};

export default NotificationsPage;