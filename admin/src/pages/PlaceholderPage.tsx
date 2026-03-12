import type { LucideIcon } from "lucide-react";

interface Props {
  icon: LucideIcon;
  name: string;
}

const PlaceholderPage = ({ icon: Icon, name }: Props) => {
  return (
    <div className="flex flex-col items-center justify-center h-[60vh] border-2 border-dashed border-[#27272a] rounded-3xl bg-[#121212]/30">
      <div className="w-20 h-20 bg-[#27272a] rounded-2xl flex items-center justify-center mb-4 text-[#40ff32]">
        <Icon size={40} />
      </div>
      <h3 className="text-xl font-bold text-white mb-2">Hamarosan érkezik!</h3>
      <p className="text-gray-500 text-center max-w-sm">
        A(z) {name} kezelőfelülete még fejlesztés alatt áll.
      </p>
    </div>
  );
};

export default PlaceholderPage;