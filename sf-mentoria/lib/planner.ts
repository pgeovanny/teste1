export type Student={id:string;name:string;examId:string;minutesPerDay:number;accuracy:number;createdAt:string};
export type Exam={id:string;name:string;subjects:string[]};
export type Task={id:string;studentId:string;examId:string;subject:string;kind:"Teoria"|"Questões"|"Revisão";date:string;minutes:number;done:boolean};
export type State={students:Student[];exams:Exam[];tasks:Task[]};
const iso=(d:Date)=>[d.getFullYear(),String(d.getMonth()+1).padStart(2,"0"),String(d.getDate()).padStart(2,"0")].join("-");
export const localToday=()=>iso(new Date());
export function addDays(date:string,n:number){const [y,m,d]=date.split("-").map(Number);const x=new Date(y,m-1,d+n,12);return iso(x)}
export function planWeek(state:State,studentId:string,start=localToday()):Task[]{
 const student=state.students.find(x=>x.id===studentId);if(!student)throw Error("Aluno não encontrado");
 const exam=state.exams.find(x=>x.id===student.examId);if(!exam?.subjects.length)throw Error("Concurso sem assuntos");
 if(!Number.isInteger(student.minutesPerDay)||student.minutesPerDay<20||student.minutesPerDay>720)throw Error("Disponibilidade inválida");
 const output:Task[]=[];const kinds:Task["kind"][]=["Teoria","Questões","Revisão"];
 for(let day=0;day<7;day++){
  const date=addDays(start,day);
  const reserved=state.tasks.filter(t=>t.studentId===studentId&&t.date===date&&t.done).reduce((sum,t)=>sum+t.minutes,0);
  let remaining=Math.max(0,student.minutesPerDay-reserved);
  let seq=0;
  while(remaining>=20){
   const subject=exam.subjects[(day*2+seq)%exam.subjects.length];
   const minutes=Math.min(remaining,student.minutesPerDay>=90?45:30);
   if(minutes<20)break;
   const exists=state.tasks.some(t=>t.studentId===studentId&&t.date===date&&t.subject===subject&&t.done);
   if(!exists)output.push({id:crypto.randomUUID(),studentId,examId:exam.id,subject,kind:kinds[(day+seq)%3],date,minutes,done:false});
   remaining-=minutes;seq++;
   if(seq>30)break;
  }
 }
 return output;
}
export function rescheduleOverdue(state:State,studentId:string,today=localToday()):{tasks:Task[],moved:number,unplaced:number}{
 const student=state.students.find(s=>s.id===studentId);if(!student)throw Error("Aluno não encontrado");
 const tasks=state.tasks.map(t=>({...t}));
 const loads=new Map<string,number>();
 for(const t of tasks)if(t.studentId===studentId&&t.date>=today)loads.set(t.date,(loads.get(t.date)||0)+t.minutes);
 const overdue=tasks.filter(t=>t.studentId===studentId&&!t.done&&t.date<today).sort((a,b)=>a.date.localeCompare(b.date));
 let moved=0,unplaced=0;
 for(const task of overdue){
  let assigned=false;
  for(let n=0;n<90;n++){const date=addDays(today,n);if((loads.get(date)||0)+task.minutes<=student.minutesPerDay){task.date=date;loads.set(date,(loads.get(date)||0)+task.minutes);assigned=true;moved++;break;}}
  if(!assigned)unplaced++;
 }
 return {tasks,moved,unplaced};
}
export const seed:State={exams:[{id:"ex-cd",name:"Câmara dos Deputados — Analista Legislativo",subjects:["Regimento Interno","Regimento Comum","LC 95/1998","Português","Direito Constitucional"]},{id:"ex-tj",name:"TJSP — Escrevente",subjects:["Português","Normas da Corregedoria","Direito Processual Civil","Informática"]}],students:[{id:"st-1",name:"Mariana Costa",examId:"ex-cd",minutesPerDay:120,accuracy:68,createdAt:"2026-11-01"},{id:"st-2",name:"Lucas Ferreira",examId:"ex-tj",minutesPerDay:90,accuracy:54,createdAt:"2026-11-02"}],tasks:[]};
