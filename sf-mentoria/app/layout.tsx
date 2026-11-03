import "./globals.css";
import type { Metadata } from "next";
export const metadata:Metadata={title:"SF Mentoria | Gestão de Estudos",description:"Plataforma privada de mentoria para concursos"};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="pt-BR"><body>{children}</body></html>}
