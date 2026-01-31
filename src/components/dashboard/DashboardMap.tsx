import React, { useState } from "react";

interface Point {
  x: number;
  y: number;
  type: "destination" | "reference";
  name?: string;
}

const MAP_WIDTH = 800;
const MAP_HEIGHT = 600;

// Predefined locations
const destinations: Point[] = [
  { x: 329.7386474609375, y: 166.1591033935547, type: 'destination', name: 'ER' },
  { x: 369.7386474609375, y: 186.1591033935547, type: 'destination', name: 'Casualty' },
  { x: 454.7386474609375, y: 173.1591033935547, type: 'destination', name: 'Pharmacy' },
  { x: 486.7386474609375, y: 265.1591033935547, type: 'destination', name: 'Canteen' },
  { x: 409.7386474609375, y: 240.1591033935547, type: 'destination', name: 'ICU' },
  { x: 425.7386474609375, y: 256.1591033935547, type: 'destination', name: 'Surgery' },
  { x: 466.7386474609375, y: 340.1591033935547, type: 'destination', name: 'Radiology' },
  { x: 467.7386474609375, y: 377.1591033935547, type: 'destination', name: 'Laboratory' },
  { x: 426.7386474609375, y: 461.1591033935547, type: 'destination', name: 'Ward A' },
  { x: 364.7386474609375, y: 487.1591033935547, type: 'destination', name: 'Ward B' },
  { x: 271.7386474609375, y: 446.1591033935547, type: 'destination', name: 'Ward C' },
  { x: 285.7386474609375, y: 392.1591033935547, type: 'destination', name: 'Ward D' },
  { x: 487.7386474609375, y: 307.1591033935547, type: 'destination', name: 'Maternity' },
  { x: 376.7386474609375, y: 371.1591033935547, type: 'destination', name: 'Pediatrics' },
];

const references: Point[] = [
  { x: 215.7386474609375, y: 63.15910339355469, type: 'reference' },
  { x: 225.7386474609375, y: 63.15910339355469, type: 'reference' },
  { x: 233.7386474609375, y: 57.15910339355469, type: 'reference' },
  { x: 245.7386474609375, y: 52.15910339355469, type: 'reference' },
  { x: 254.7386474609375, y: 48.15910339355469, type: 'reference' },
  { x: 259.7386474609375, y: 53.15910339355469, type: 'reference' },
  { x: 263.7386474609375, y: 63.15910339355469, type: 'reference' },
  { x: 266.7386474609375, y: 73.15910339355469, type: 'reference' },
  { x: 271.7386474609375, y: 82.15910339355469, type: 'reference' },
  { x: 274.7386474609375, y: 91.15910339355469, type: 'reference' },
  { x: 277.7386474609375, y: 100.15910339355469, type: 'reference' },
  { x: 277.7386474609375, y: 107.15910339355469, type: 'reference' },
  { x: 282.7386474609375, y: 118.15910339355469, type: 'reference' },
  { x: 281.7386474609375, y: 134.1591033935547, type: 'reference' },
  { x: 287.7386474609375, y: 146.1591033935547, type: 'reference' },
  { x: 290.7386474609375, y: 157.1591033935547, type: 'reference' },
  { x: 290.7386474609375, y: 163.1591033935547, type: 'reference' },
  { x: 299.7386474609375, y: 159.1591033935547, type: 'reference' },
  { x: 306.7386474609375, y: 160.1591033935547, type: 'reference' },
  { x: 314.7386474609375, y: 156.1591033935547, type: 'reference' },
  { x: 293.7386474609375, y: 171.1591033935547, type: 'reference' },
  { x: 295.7386474609375, y: 180.1591033935547, type: 'reference' },
  { x: 298.7386474609375, y: 189.1591033935547, type: 'reference' },
  { x: 300.7386474609375, y: 199.1591033935547, type: 'reference' },
  { x: 303.7386474609375, y: 212.1591033935547, type: 'reference' },
  { x: 306.7386474609375, y: 220.1591033935547, type: 'reference' },
  { x: 310.7386474609375, y: 228.1591033935547, type: 'reference' },
  { x: 321.7386474609375, y: 225.1591033935547, type: 'reference' },
  { x: 335.7386474609375, y: 219.1591033935547, type: 'reference' },
  { x: 346.7386474609375, y: 215.1591033935547, type: 'reference' },
  { x: 358.7386474609375, y: 213.1591033935547, type: 'reference' },
  { x: 370.7386474609375, y: 209.1591033935547, type: 'reference' },
  { x: 382.7386474609375, y: 208.1591033935547, type: 'reference' },
  { x: 396.7386474609375, y: 208.1591033935547, type: 'reference' },
  { x: 407.7386474609375, y: 208.1591033935547, type: 'reference' },
  { x: 417.7386474609375, y: 210.1591033935547, type: 'reference' },
  { x: 430.7386474609375, y: 215.1591033935547, type: 'reference' },
  { x: 442.7386474609375, y: 217.1591033935547, type: 'reference' },
  { x: 453.7386474609375, y: 223.1591033935547, type: 'reference' },
  { x: 465.7386474609375, y: 226.1591033935547, type: 'reference' },
  { x: 475.7386474609375, y: 233.1591033935547, type: 'reference' },
  { x: 485.7386474609375, y: 241.1591033935547, type: 'reference' },
  { x: 495.7386474609375, y: 248.1591033935547, type: 'reference' },
  { x: 502.7386474609375, y: 261.1591033935547, type: 'reference' },
  { x: 512.7386474609375, y: 272.1591033935547, type: 'reference' },
  { x: 519.7386474609375, y: 284.1591033935547, type: 'reference' },
  { x: 525.7386474609375, y: 295.1591033935547, type: 'reference' },
  { x: 535.7386474609375, y: 299.1591033935547, type: 'reference' },
  { x: 546.7386474609375, y: 306.1591033935547, type: 'reference' },
  { x: 556.7386474609375, y: 311.1591033935547, type: 'reference' },
  { x: 313.7386474609375, y: 241.1591033935547, type: 'reference' },
  { x: 317.7386474609375, y: 252.1591033935547, type: 'reference' },
  { x: 320.7386474609375, y: 263.1591033935547, type: 'reference' },
  { x: 325.7386474609375, y: 277.1591033935547, type: 'reference' },
  { x: 329.7386474609375, y: 291.1591033935547, type: 'reference' },
  { x: 335.7386474609375, y: 302.1591033935547, type: 'reference' },
  { x: 338.7386474609375, y: 312.1591033935547, type: 'reference' },
  { x: 345.7386474609375, y: 309.1591033935547, type: 'reference' },
  { x: 353.7386474609375, y: 305.1591033935547, type: 'reference' },
  { x: 364.7386474609375, y: 304.1591033935547, type: 'reference' },
  { x: 375.7386474609375, y: 303.1591033935547, type: 'reference' },
  { x: 388.7386474609375, y: 300.1591033935547, type: 'reference' },
  { x: 401.7386474609375, y: 301.1591033935547, type: 'reference' },
  { x: 411.7386474609375, y: 308.1591033935547, type: 'reference' },
  { x: 422.7386474609375, y: 318.1591033935547, type: 'reference' },
  { x: 429.7386474609375, y: 322.1591033935547, type: 'reference' },
  { x: 435.7386474609375, y: 331.1591033935547, type: 'reference' },
  { x: 440.7386474609375, y: 339.1591033935547, type: 'reference' },
  { x: 444.7386474609375, y: 352.1591033935547, type: 'reference' },
  { x: 445.7386474609375, y: 366.1591033935547, type: 'reference' },
  { x: 445.7386474609375, y: 377.1591033935547, type: 'reference' },
  { x: 439.7386474609375, y: 392.1591033935547, type: 'reference' },
  { x: 433.7386474609375, y: 401.1591033935547, type: 'reference' },
  { x: 425.7386474609375, y: 412.1591033935547, type: 'reference' },
  { x: 419.7386474609375, y: 419.1591033935547, type: 'reference' },
  { x: 412.7386474609375, y: 427.1591033935547, type: 'reference' },
  { x: 405.7386474609375, y: 435.1591033935547, type: 'reference' },
  { x: 395.7386474609375, y: 435.1591033935547, type: 'reference' },
  { x: 385.7386474609375, y: 439.1591033935547, type: 'reference' },
  { x: 376.7386474609375, y: 437.1591033935547, type: 'reference' },
  { x: 365.7386474609375, y: 437.1591033935547, type: 'reference' },
  { x: 358.7386474609375, y: 436.1591033935547, type: 'reference' },
  { x: 351.7386474609375, y: 433.1591033935547, type: 'reference' },
  { x: 343.7386474609375, y: 427.1591033935547, type: 'reference' },
  { x: 336.7386474609375, y: 425.1591033935547, type: 'reference' },
  { x: 331.7386474609375, y: 420.1591033935547, type: 'reference' },
  { x: 326.7386474609375, y: 416.1591033935547, type: 'reference' },
  { x: 321.7386474609375, y: 409.1591033935547, type: 'reference' },
  { x: 315.7386474609375, y: 401.1591033935547, type: 'reference' },
  { x: 312.7386474609375, y: 393.1591033935547, type: 'reference' },
  { x: 312.7386474609375, y: 383.1591033935547, type: 'reference' },
  { x: 311.7386474609375, y: 372.1591033935547, type: 'reference' },
  { x: 311.7386474609375, y: 364.1591033935547, type: 'reference' },
  { x: 314.7386474609375, y: 355.1591033935547, type: 'reference' },
  { x: 318.7386474609375, y: 348.1591033935547, type: 'reference' },
  { x: 322.7386474609375, y: 340.1591033935547, type: 'reference' },
  { x: 325.7386474609375, y: 332.1591033935547, type: 'reference' },
  { x: 330.7386474609375, y: 324.1591033935547, type: 'reference' },
  { x: 330.7386474609375, y: 433.1591033935547, type: 'reference' },
  { x: 325.7386474609375, y: 440.1591033935547, type: 'reference' },
  { x: 319.7386474609375, y: 447.1591033935547, type: 'reference' },
  { x: 313.7386474609375, y: 456.1591033935547, type: 'reference' },
  { x: 307.7386474609375, y: 466.1591033935547, type: 'reference' },
  { x: 301.7386474609375, y: 472.1591033935547, type: 'reference' },
  { x: 290.7386474609375, y: 478.1591033935547, type: 'reference' },
  { x: 329.7386474609375, y: 456.1591033935547, type: 'reference' },
  { x: 335.7386474609375, y: 464.1591033935547, type: 'reference' },
  { x: 313.7386474609375, y: 476.1591033935547, type: 'reference' },
  { x: 321.7386474609375, y: 481.1591033935547, type: 'reference' },
  { x: 325.7386474609375, y: 489.1591033935547, type: 'reference' },
  { x: 333.7386474609375, y: 496.1591033935547, type: 'reference' },
  { x: 344.7386474609375, y: 506.1591033935547, type: 'reference' },
  { x: 355.7386474609375, y: 516.1591033935547, type: 'reference' },
  { x: 365.7386474609375, y: 526.1591033935547, type: 'reference' },
  { x: 372.7386474609375, y: 534.1591033935547, type: 'reference' },
  { x: 381.7386474609375, y: 540.1591033935547, type: 'reference' },
  { x: 392.7386474609375, y: 539.1591033935547, type: 'reference' },
  { x: 398.7386474609375, y: 529.1591033935547, type: 'reference' },
  { x: 405.7386474609375, y: 519.1591033935547, type: 'reference' },
  { x: 375.7386474609375, y: 551.1591033935547, type: 'reference' },
  { x: 367.7386474609375, y: 558.1591033935547, type: 'reference' },
  { x: 437.7386474609375, y: 312.1591033935547, type: 'reference' },
  { x: 445.7386474609375, y: 304.1591033935547, type: 'reference' },
  { x: 453.7386474609375, y: 297.1591033935547, type: 'reference' },
  { x: 460.7386474609375, y: 293.1591033935547, type: 'reference' },
  { x: 471.7386474609375, y: 293.1591033935547, type: 'reference' },
  { x: 484.7386474609375, y: 288.1591033935547, type: 'reference' },
  { x: 497.7386474609375, y: 290.1591033935547, type: 'reference' },
  { x: 507.7386474609375, y: 289.1591033935547, type: 'reference' },
  { x: 382.7386474609375, y: 468.1591033935547, type: 'reference' },
  { x: 389.7386474609375, y: 459.1591033935547, type: 'reference' },
  { x: 385.7386474609375, y: 479.1591033935547, type: 'reference' },
  { x: 398.7386474609375, y: 471.1591033935547, type: 'reference' },
];

const allPoints = [...destinations, ...references];

// Simple A* implementation for shortest path
function findShortestPath(start: Point, end: Point, waypoints: Point[]): Point[] {
  // For simplicity, use Euclidean distance and connect nearby points
  const graph: { [key: string]: { point: Point; neighbors: { point: Point; dist: number }[] } } = {};

  allPoints.forEach(p => {
    const key = `${p.x},${p.y}`;
    graph[key] = { point: p, neighbors: [] };
  });

  // Connect points within a certain distance
  allPoints.forEach(p1 => {
    allPoints.forEach(p2 => {
      if (p1 !== p2) {
        const dist = Math.sqrt((p1.x - p2.x) ** 2 + (p1.y - p2.y) ** 2);
        if (dist < 50) { // Connect if close enough
          const key1 = `${p1.x},${p1.y}`;
          const key2 = `${p2.x},${p2.y}`;
          graph[key1].neighbors.push({ point: p2, dist });
        }
      }
    });
  });

  // A* algorithm (simplified)
  const startKey = `${start.x},${start.y}`;
  const endKey = `${end.x},${end.y}`;
  const openSet = [startKey];
  const cameFrom: { [key: string]: string } = {};
  const gScore: { [key: string]: number } = {};
  const fScore: { [key: string]: number } = {};

  allPoints.forEach(p => {
    const key = `${p.x},${p.y}`;
    gScore[key] = Infinity;
    fScore[key] = Infinity;
  });

  gScore[startKey] = 0;
  fScore[startKey] = Math.sqrt((start.x - end.x) ** 2 + (start.y - end.y) ** 2);

  while (openSet.length > 0) {
    const current = openSet.reduce((a, b) => fScore[a] < fScore[b] ? a : b);
    if (current === endKey) {
      // Reconstruct path
      const path: Point[] = [];
      let temp = current;
      while (temp) {
        path.unshift(graph[temp].point);
        temp = cameFrom[temp];
      }
      return path;
    }

    openSet.splice(openSet.indexOf(current), 1);

    graph[current].neighbors.forEach(neighbor => {
      const neighborKey = `${neighbor.point.x},${neighbor.point.y}`;
      const tentativeGScore = gScore[current] + neighbor.dist;
      if (tentativeGScore < gScore[neighborKey]) {
        cameFrom[neighborKey] = current;
        gScore[neighborKey] = tentativeGScore;
        fScore[neighborKey] = gScore[neighborKey] + Math.sqrt((neighbor.point.x - end.x) ** 2 + (neighbor.point.y - end.y) ** 2);
        if (!openSet.includes(neighborKey)) {
          openSet.push(neighborKey);
        }
      }
    });
  }

  return []; // No path found
}

export default function DashboardMap() {
  const [startDest, setStartDest] = useState<string>('');
  const [endDest, setEndDest] = useState<string>('');
  const [path, setPath] = useState<Point[]>([]);

  const handleCalculatePath = () => {
    const start = destinations.find(d => d.name === startDest);
    const end = destinations.find(d => d.name === endDest);
    if (start && end) {
      const shortestPath = findShortestPath(start, end, references);
      setPath(shortestPath);
    }
  };

  return (
    <div>
      <div className="mb-4 flex gap-4 items-center">
        <select value={startDest} onChange={(e) => setStartDest(e.target.value)} className="border p-2">
          <option value="">Select Start</option>
          {destinations.map(d => <option key={d.name} value={d.name}>{d.name}</option>)}
        </select>
        <select value={endDest} onChange={(e) => setEndDest(e.target.value)} className="border p-2">
          <option value="">Select End</option>
          {destinations.map(d => <option key={d.name} value={d.name}>{d.name}</option>)}
        </select>
        <button onClick={handleCalculatePath} className="bg-blue-500 text-white px-4 py-2 rounded">Find Path</button>
      </div>
      <div
        style={{
          width: MAP_WIDTH,
          height: MAP_HEIGHT,
          background: `url('/src/assets/floor_plan.png') no-repeat center/contain`,
          position: "relative",
          border: "2px solid #333",
        }}
      >
        {/* Draw path */}
        {path.length > 1 && (
          <svg style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%' }}>
            <path
              d={`M ${path[0].x} ${path[0].y} ${path.slice(1).map(p => `L ${p.x} ${p.y}`).join(' ')}`}
              stroke="blue"
              strokeWidth="3"
              fill="none"
            />
          </svg>
        )}

        {/* Draw reference points */}
        {references.map((pt, i) => (
          <div
            key={`ref-${i}`}
            style={{
              position: "absolute",
              left: pt.x - 2,
              top: pt.y - 2,
              width: 4,
              height: 4,
              borderRadius: "50%",
              background: "#ccc",
              pointerEvents: "none",
            }}
          />
        ))}

        {/* Draw destinations */}
        {destinations.map((pt, i) => (
          <div
            key={`dest-${i}`}
            style={{
              position: "absolute",
              left: pt.x - 8,
              top: pt.y - 8,
              width: 16,
              height: 16,
              borderRadius: "50%",
              background: "#ff5252",
              border: "2px solid #fff",
              boxShadow: "0 0 6px #0007",
              pointerEvents: "none",
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontSize: '10px',
              fontWeight: 'bold',
            }}
            title={pt.name}
          >
            {pt.name}
          </div>
        ))}
      </div>
    </div>
  );
}
