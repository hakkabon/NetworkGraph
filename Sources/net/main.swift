import ArgumentParser
import Foundation
import Files
import GraphViz
import NetworkGraph
import os.log

struct Net: ParsableCommand {

    @Argument(help: "File name of graph data ('.csv' format)") var filename: String = ""
    @Flag(name: [.short, .long], help: "Weighted graph") var weighted: Bool = false

    mutating func run() throws {
        do {
            guard filename.count > 0 else { return }
            let graphViz: GraphViz.Graph? = nil
            let file = try File(path: filename)

            if weighted {
                let data: [(String,String,String)] = csvparse(string: try file.readAsString(), separator: " ").map { $0.splat3() }
                let graph = AdjacentGraph<String,Double>(data)
                print(graph)
                // graphViz = graph.transform()
            } else {
                let data: [(String,String)] = csvparse(string: try file.readAsString(), separator: " ").map { $0.splat2() }
                let graph = AdjacentGraph<String,NoProperty>(data)
                print(graph)
                // graphViz = graph.transform()
            }

            if let graphViz = graphViz {
                // When things go wrong ... use this.
                print(DOTEncoder().encode(graphViz))
                
                // Render image using dot layout algorithm.
                graphViz.render(using: LayoutAlgorithm.dot, to: Format.pdf) { result in
                    switch result {
                    case .success(let data):
                        let filename = randomFilename(length: 8, format: Format.pdf)
                        let file = try! Folder.current.createFile(named: filename, contents: data)
                        shell("open", file.path)
                    case .failure(let error):
                        os_log("could not render dot-file for reason: %@", log: OSLog.default, type: .error, "\(error.localizedDescription)")
                    }
                }
            }
        } catch let error {
            os_log("failed execution for reason: %@", log: OSLog.default, type: .error, "\(error.localizedDescription)")
        }
    }
}

Net.main()

@discardableResult
func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

func randomFilename(length: Int, format: GraphViz.Format) -> String {
    return  RandomString().randomize(length: length) + ".\(format)"
}

struct RandomString {
    static let characters = """
    abcdefghijklmnopqrstuvwxyz\
    ABCDEFGHIJKLMNOPQRSTUVWXYZ\
    0123456789
    """
    static let shared = RandomString()
    let chars = characters.map { $0 }
    
    func randomize(length: Int) -> String {
        var str = ""
        for _ in 0..<length {
            str.append(chars.randomElement()!)
        }
        return str
    }
}

/*
let graph_1 = UnweightedGraph<Int>( parse(file: "data-1", ofType: "csv").map { $0.splat2() } )
print(graph_1)

let graph_2 = UnweightedGraph<String>( parse(file: "data-2", ofType: "csv").map { $0.splat2() } )
print(graph_2)

let sedgewicktiny = UnweightedGraph<Int>( parse(file: "sedgewick-tiny", ofType: "csv").map { $0.splat2() } )
print(sedgewicktiny)

let sedgewickmedium = UnweightedGraph<Int>( parse(file: "sedgewick-medium", ofType: "csv").map { $0.splat2() } )
print(sedgewickmedium)

let cityGraph = WeightedGraph<String,Int>( parse(file: "usa-map", ofType: "csv").map { $0.splat3() } )
print(cityGraph)

let mst = cityGraph.mst()
print(cityGraph.printMST(edges: mst))
print("total weight: ", cityGraph.totalWeight(mst))

let (distances, pathDict) = cityGraph.dijkstra(root: "New York", startDistance: 0)
print(distances["San Francisco"] ?? 0)
print(distances["Los Angeles"] ?? 0)
print( cityGraph.path(from: "New York", to: "San Francisco", pathDict: pathDict) )

let spEWD = WeightedGraph<Int,Float>( parse(file: "1000EWD", ofType: "csv").map { $0.splat3() } )
print(spEWD)
let (distancesEWD, pathEWD) = spEWD.dijkstra(root: 0, startDistance: 0)
print(distancesEWD[827] ?? 0)
print( spEWD.path(from: 0, to: 827, pathDict: pathEWD) )

*/
