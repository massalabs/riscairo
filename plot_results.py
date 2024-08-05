import re
import numpy as np
import matplotlib.pyplot as plt

def parse_test_report(filename):
    test_results = []
    with open(filename, 'r') as file:
        content = file.read()

    rust_tests_pattern_cpu = re.compile(
        r'\[PASS\] tests::rust_tests::test_(\w+)_cpu_(\d+) \(gas: ~(\d+)\)\n\s+steps: (\d+)\n\s+memory holes: (\d+)\n\s+builtins: \((.*?)\)\n\s+syscalls: \(\)',
        re.DOTALL
    )

    matches_cpu = rust_tests_pattern_cpu.findall(content)
    for match in matches_cpu:
        test_name, input_data_size, gas, steps, memory_holes, builtins = match
        builtins_dict = dict(re.findall(r'"(\w+)": (\d+)', builtins))
        test_results.append({
            'test_name': test_name,
            'category': 'cpu',
            'input_data_size': int(input_data_size),
            'gas': int(gas),
            'steps': int(steps),
            'memory_holes': int(memory_holes),
            'builtins': {k: int(v) for k, v in builtins_dict.items()}
        })

    rust_tests_pattern_local = re.compile(
        r'\[PASS\] tests::rust_tests::test_(\w+)_local_(\d+) \(gas: ~(\d+)\)\n\s+steps: (\d+)\n\s+memory holes: (\d+)\n\s+builtins: \((.*?)\)\n\s+syscalls: \(\)',
        re.DOTALL
    )

    matches_local = rust_tests_pattern_local.findall(content)
    for match in matches_local:
        test_name, input_data_size, gas, steps, memory_holes, builtins = match
        builtins_dict = dict(re.findall(r'"(\w+)": (\d+)', builtins))
        test_results.append({
            'test_name': test_name,
            'category': 'local',
            'input_data_size': int(input_data_size),
            'gas': int(gas),
            'steps': int(steps),
            'memory_holes': int(memory_holes),
            'builtins': {k: int(v) for k, v in builtins_dict.items()}
        })

    # Sort the test results by test_name, category, and input_data_size
    test_results.sort(key=lambda x: (x['test_name'], x['category'], x['input_data_size']))

    return test_results

def plot_results(test_results):
    test_names = list(set(result['test_name'] for result in test_results))
    num_tests = len(test_names)
    
    fig, axes = plt.subplots(1, num_tests, figsize=(15, 5))
    
    for ax, test_name in zip(axes, test_names):
        test_data = [result for result in test_results if result['test_name'] == test_name]
        
        input_sizes = [data['input_data_size'] for data in test_data]
        gas_values = [data['gas'] for data in test_data]
        categories = [data['category'] for data in test_data]
        
        # Sort data by input complexity
        sorted_indices = np.argsort(input_sizes)
        input_sizes = np.array(input_sizes)[sorted_indices]
        gas_values = np.array(gas_values)[sorted_indices]
        categories = np.array(categories)[sorted_indices]

        color_map = {'cpu': 'b', 'local': 'r'}
        marker_map = {'cpu': 'o', 'local': 's'}
        label_map = {'cpu': 'CPU', 'local': 'Local'}

        plotted_labels = set()
        for i in range(len(input_sizes)):
            category = categories[i]
            label = label_map[category] if category not in plotted_labels else ""
            ax.scatter(input_sizes[i], gas_values[i], color=color_map[category], marker=marker_map[category], label=label)
            plotted_labels.add(category)

        ax.set_xlabel('Input Complexity')
        ax.set_ylabel('Gas', color='tab:blue')
        ax.tick_params(axis='y', labelcolor='tab:blue')
        ax.set_title(f'Test: {test_name}')

        handles, labels = ax.get_legend_handles_labels()
        by_label = dict(zip(labels, handles))
        ax.legend(by_label.values(), by_label.keys())

        # Perform linear fit for CPU and Local categories
        for category in ['cpu', 'local']:
            category_data = [(input_sizes[i], gas_values[i]) for i in range(len(categories)) if categories[i] == category]
            if category_data:
                x, y = zip(*category_data)
                x = np.array(x)
                y = np.array(y)
                coefficients = np.polyfit(x, y, 1)  # Linear fit
                slope, intercept = coefficients
                print(f"Linear fit for {label_map[category]} in {test_name}:")
                print(f"  Intercept (gas used at zero input complexity): {intercept:.2f}")
                print(f"  Slope (gas per unit of input complexity): {slope:.2f}")
                
                # Plot the linear fit line
                fit_y = intercept + slope * x
                ax.plot(x, fit_y, color=color_map[category], linestyle='dashed')
    
    plt.tight_layout()
    plt.savefig('bench.png')
    plt.show()

def main():
    filename = 'test_report.txt'
    test_results = parse_test_report(filename)
    plot_results(test_results)

if __name__ == "__main__":
    main()
